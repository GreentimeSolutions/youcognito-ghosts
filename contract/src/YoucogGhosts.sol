// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {GhostRenderer} from "./GhostRenderer.sol";

/// @title Youcognito Ghosts: 1 of 1,000 on-chain pixel ghosts on Base
/// @notice Non-upgradeable. The only ways a token is created are `mint` (public, one per wallet)
///         and `ownerMint` (owner reserve, max 10). The contract never holds ETH or YOUCOG:
///         mint payments go straight from the minter to the faucet. There is no withdraw function.
contract YoucogGhosts is ERC721, ERC2981, Ownable2Step, Pausable, ReentrancyGuard, EIP712 {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant OWNER_RESERVE = 10;
    uint96 public constant ROYALTY_BPS = 500; // 5%
    bytes32 public constant MINT_TYPEHASH = keccak256("Mint(address minter,uint256 fid,uint256 deadline)");

    /// @notice YOUCOG ERC-20 on Base (from claim-forge-app src/lib/youcog/faucet.server.ts TOKEN).
    IERC20 public immutable youcog;
    /// @notice Receives every YOUCOG mint payment. Fixed at deploy.
    address public immutable faucet;

    uint256 public totalSupply;
    uint256 public reserveMinted;
    /// @notice YOUCOG price in base units (18 decimals) for token IDs above `freeUntil`. Defaults to 0.
    uint256 public price;
    /// @notice Token IDs 1..freeUntil are free (gas only). Defaults to 100.
    uint256 public freeUntil = 100;
    /// @notice If non-zero, public mints need an EIP-712 voucher signed by this key (one per Farcaster ID).
    address public voucherSigner;

    mapping(address => bool) public hasMinted;
    mapping(uint256 => bool) public fidUsed;
    mapping(uint256 => uint8[6]) internal _traits;

    event Minted(address indexed to, uint256 indexed tokenId, uint8[6] traits, uint256 paid, uint256 fid);
    event PriceSet(uint256 price);
    event FreeUntilSet(uint256 freeUntil);
    event VoucherSignerSet(address signer);
    event RoyaltyReceiverSet(address receiver);

    error ZeroAddress();
    error SoldOut();
    error ReserveExhausted();
    error AlreadyMinted();
    error InvalidTraits();
    error OwnerMustMintFirst();
    error PriceAboveMax(uint256 price, uint256 maxPrice);
    error BadVoucher();
    error VoucherExpired();
    error FidUsed();
    error BadPhase();
    error RenounceDisabled();

    constructor(address owner_, address faucet_, address royaltyReceiver_, address youcog_)
        ERC721("Youcognito Ghosts", "YGHOST")
        Ownable(owner_)
        EIP712("YoucogGhosts", "1")
    {
        if (faucet_ == address(0) || royaltyReceiver_ == address(0) || youcog_ == address(0)) revert ZeroAddress();
        faucet = faucet_;
        youcog = IERC20(youcog_);
        _setDefaultRoyalty(royaltyReceiver_, ROYALTY_BPS);
        _pause(); // starts paused: owner mints #1, then unpauses
    }

    // ---------------------------------------------------------------- minting

    /// @notice Public mint, one per wallet. `maxPrice` protects the minter from a price change in flight.
    ///         `fid`, `deadline`, `sig` are ignored while `voucherSigner` is zero.
    function mint(uint8[6] calldata traits, uint256 maxPrice, uint256 fid, uint256 deadline, bytes calldata sig)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 id)
    {
        if (totalSupply == 0) revert OwnerMustMintFirst();
        if (hasMinted[msg.sender]) revert AlreadyMinted();
        if (totalSupply + (OWNER_RESERVE - reserveMinted) >= MAX_SUPPLY) revert SoldOut();
        if (voucherSigner != address(0)) {
            if (block.timestamp > deadline) revert VoucherExpired();
            if (fidUsed[fid]) revert FidUsed();
            bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(MINT_TYPEHASH, msg.sender, fid, deadline)));
            if (ECDSA.recover(digest, sig) != voucherSigner) revert BadVoucher();
            fidUsed[fid] = true;
        } else {
            fid = 0;
        }
        hasMinted[msg.sender] = true;
        id = totalSupply + 1;
        uint256 cost = id <= freeUntil ? 0 : price;
        if (cost > maxPrice) revert PriceAboveMax(cost, maxPrice);
        if (cost != 0) youcog.safeTransferFrom(msg.sender, faucet, cost);
        _mintGhost(msg.sender, id, traits, cost, fid);
    }

    /// @notice Owner reserve (10 total, includes #1). Works while paused. Not subject to one-per-wallet.
    function ownerMint(address to, uint8[6] calldata traits) external onlyOwner nonReentrant returns (uint256 id) {
        if (reserveMinted >= OWNER_RESERVE) revert ReserveExhausted();
        if (totalSupply >= MAX_SUPPLY) revert SoldOut();
        reserveMinted++;
        id = totalSupply + 1;
        _mintGhost(to, id, traits, 0, 0);
    }

    function _mintGhost(address to, uint256 id, uint8[6] calldata traits, uint256 paid, uint256 fid) internal {
        for (uint256 s; s < 6; ++s) {
            if (traits[s] > GhostRenderer.slotCount(s)) revert InvalidTraits();
        }
        totalSupply = id;
        _traits[id] = traits;
        emit Minted(to, id, traits, paid, fid);
        _safeMint(to, id);
    }

    /// @notice Price for the next public mint.
    function currentPrice() external view returns (uint256) {
        return totalSupply + 1 <= freeUntil ? 0 : price;
    }

    // ---------------------------------------------------------------- views

    function traitsOf(uint256 id) external view returns (uint8[6] memory) {
        _requireOwned(id);
        return _traits[id];
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        _requireOwned(id);
        return GhostRenderer.tokenURI(id, _traits[id]);
    }

    function svgOf(uint256 id) external view returns (string memory) {
        _requireOwned(id);
        return GhostRenderer.svg(_traits[id]);
    }

    /// @notice Preview any outfit before minting.
    function previewSvg(uint8[6] calldata traits) external pure returns (string memory) {
        for (uint256 s; s < 6; ++s) {
            if (traits[s] > GhostRenderer.slotCount(s)) revert InvalidTraits();
        }
        return GhostRenderer.svg(traits);
    }

    function supportsInterface(bytes4 i) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(i);
    }

    // ---------------------------------------------------------------- owner controls

    function setPrice(uint256 p) external onlyOwner {
        price = p;
        emit PriceSet(p);
    }

    function setFreeUntil(uint256 n) external onlyOwner {
        if (n > MAX_SUPPLY) revert BadPhase();
        freeUntil = n;
        emit FreeUntilSet(n);
    }

    function setVoucherSigner(address s) external onlyOwner {
        voucherSigner = s;
        emit VoucherSignerSet(s);
    }

    /// @notice Changes the royalty receiver; the rate stays fixed at 5%.
    function setRoyaltyReceiver(address r) external onlyOwner {
        if (r == address(0)) revert ZeroAddress();
        _setDefaultRoyalty(r, ROYALTY_BPS);
        emit RoyaltyReceiverSet(r);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Disabled so the collection can never be left ownerless by accident.
    function renounceOwnership() public view override onlyOwner {
        revert RenounceDisabled();
    }
}
