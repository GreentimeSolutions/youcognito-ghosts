// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {YoucogGhosts} from "../src/YoucogGhosts.sol";

contract MockYoucog is ERC20 {
    constructor() ERC20("Youcognito", "YOUCOG") {}
    function mint(address to, uint256 a) external { _mint(to, a); }
}

contract Reenter is IERC721Receiver {
    YoucogGhosts g;
    constructor(YoucogGhosts g_) { g = g_; }
    function go() external { uint8[6] memory t; g.mint(t, 0, 0, 0, ""); }
    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        uint8[6] memory t;
        g.mint(t, 0, 0, 0, ""); // must revert
        return this.onERC721Received.selector;
    }
}

contract NoReceiver {}

contract GhostsTest is Test {
    YoucogGhosts g;
    MockYoucog tok;
    address owner = makeAddr("owner");
    address faucet = makeAddr("faucet");
    address royalty = makeAddr("royalty");
    uint256 signerPk = 0xA11CE;
    address signer;
    uint8[6] none;
    uint8[6] full = [uint8(9), 7, 6, 5, 5, 6];

    function setUp() public {
        tok = new MockYoucog();
        g = new YoucogGhosts(owner, faucet, royalty, address(tok));
        signer = vm.addr(signerPk);
    }

    function _open() internal {
        vm.startPrank(owner);
        g.ownerMint(owner, [uint8(1), 1, 0, 0, 0, 0]);
        g.unpause();
        vm.stopPrank();
    }

    function _user(uint256 i) internal pure returns (address) { return address(uint160(0x100000 + i)); }

    function _mintAs(address u) internal returns (uint256) {
        vm.prank(u);
        return g.mint(none, type(uint256).max, 0, 0, "");
    }

    // ---- deploy state
    function test_InitialState() public view {
        assertEq(g.owner(), owner);
        assertEq(g.faucet(), faucet);
        assertEq(address(g.youcog()), address(tok));
        assertEq(g.price(), 0);
        assertEq(g.freeUntil(), 100);
        assertTrue(g.paused());
        assertEq(g.totalSupply(), 0);
        assertEq(g.voucherSigner(), address(0));
        assertEq(g.name(), "Youcognito Ghosts");
    }

    function test_ConstructorZeroChecks() public {
        vm.expectRevert(YoucogGhosts.ZeroAddress.selector);
        new YoucogGhosts(owner, address(0), royalty, address(tok));
        vm.expectRevert(YoucogGhosts.ZeroAddress.selector);
        new YoucogGhosts(owner, faucet, address(0), address(tok));
        vm.expectRevert(YoucogGhosts.ZeroAddress.selector);
        new YoucogGhosts(owner, faucet, royalty, address(0));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));
        new YoucogGhosts(address(0), faucet, royalty, address(tok));
    }

    // ---- reserve and #1
    function test_OwnerMintsNumberOneWhilePaused() public {
        vm.prank(owner);
        uint256 id = g.ownerMint(owner, full);
        assertEq(id, 1);
        assertEq(g.ownerOf(1), owner);
        assertEq(g.reserveMinted(), 1);
    }

    function test_PublicCannotMintBeforeOwnerFirst() public {
        vm.prank(owner);
        g.unpause();
        vm.expectRevert(YoucogGhosts.OwnerMustMintFirst.selector);
        _mintAs(_user(1));
    }

    function test_ReserveCapTen() public {
        vm.startPrank(owner);
        for (uint256 i; i < 10; i++) g.ownerMint(owner, none);
        vm.expectRevert(YoucogGhosts.ReserveExhausted.selector);
        g.ownerMint(owner, none);
        vm.stopPrank();
        assertEq(g.balanceOf(owner), 10);
    }

    function test_OwnerMintOnlyOwner() public {
        vm.prank(_user(1));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _user(1)));
        g.ownerMint(_user(1), none);
    }

    // ---- max supply, reserve held back
    function test_MaxSupplyAndReserveHeldBack() public {
        _open();
        // 1 reserve used; public gets exactly 1000 - 10 = 990
        for (uint256 i = 1; i <= 990; i++) _mintAs(_user(i));
        assertEq(g.totalSupply(), 991);
        vm.expectRevert(YoucogGhosts.SoldOut.selector);
        _mintAs(_user(5000));
        vm.startPrank(owner);
        for (uint256 i; i < 9; i++) g.ownerMint(owner, none);
        vm.expectRevert(YoucogGhosts.ReserveExhausted.selector);
        g.ownerMint(owner, none);
        vm.stopPrank();
        assertEq(g.totalSupply(), 1000);
        assertEq(g.ownerOf(1000), owner);
        vm.expectRevert();
        g.ownerOf(1001);
    }

    // ---- one per wallet
    function test_OnePerWallet() public {
        _open();
        _mintAs(_user(1));
        vm.expectRevert(YoucogGhosts.AlreadyMinted.selector);
        _mintAs(_user(1));
        // transferring away does not reset it
        vm.prank(_user(1));
        g.transferFrom(_user(1), _user(2), 2);
        vm.expectRevert(YoucogGhosts.AlreadyMinted.selector);
        _mintAs(_user(1));
    }

    function test_ReentrancyBlocked() public {
        _open();
        Reenter r = new Reenter(g);
        vm.expectRevert(); // nonReentrant
        r.go();
    }

    function test_NonReceiverContractCannotMint() public {
        _open();
        NoReceiver n = new NoReceiver();
        vm.prank(address(n));
        vm.expectRevert();
        g.mint(none, 0, 0, 0, "");
    }

    // ---- pricing phases and YOUCOG to faucet
    function test_FreeFirst100EvenWithPrice() public {
        _open();
        vm.prank(owner);
        g.setPrice(840e18);
        for (uint256 i = 2; i <= 100; i++) {
            vm.prank(_user(i));
            g.mint(none, 0, 0, 0, ""); // maxPrice 0 still works: free phase
        }
        assertEq(g.totalSupply(), 100);
        assertEq(tok.balanceOf(faucet), 0);
        assertEq(g.currentPrice(), 840e18);
        // #101 must pay
        address u = _user(101);
        vm.prank(u);
        vm.expectRevert(abi.encodeWithSelector(YoucogGhosts.PriceAboveMax.selector, 840e18, 0));
        g.mint(none, 0, 0, 0, "");
        tok.mint(u, 1000e18);
        vm.startPrank(u);
        tok.approve(address(g), 840e18);
        g.mint(none, 840e18, 0, 0, "");
        vm.stopPrank();
        assertEq(tok.balanceOf(faucet), 840e18);
        assertEq(tok.balanceOf(u), 160e18);
        assertEq(tok.balanceOf(address(g)), 0);
    }

    function test_PriceDefaultZeroAfterFreePhase() public {
        _open();
        vm.prank(owner);
        g.setFreeUntil(1);
        _mintAs(_user(1)); // #2, price 0
        assertEq(tok.balanceOf(faucet), 0);
    }

    function test_PaidMintNeedsAllowanceAndBalance() public {
        _open();
        vm.startPrank(owner);
        g.setFreeUntil(1);
        g.setPrice(100e18);
        vm.stopPrank();
        address u = _user(7);
        vm.prank(u);
        vm.expectRevert(); // no allowance
        g.mint(none, 100e18, 0, 0, "");
        assertFalse(g.hasMinted(u));
    }

    function test_SetFreeUntilBounds() public {
        vm.startPrank(owner);
        g.setFreeUntil(1000);
        vm.expectRevert(YoucogGhosts.BadPhase.selector);
        g.setFreeUntil(1001);
        vm.stopPrank();
    }

    // ---- royalties
    function test_Royalty5Percent() public {
        (address r, uint256 amt) = g.royaltyInfo(1, 10_000);
        assertEq(r, royalty);
        assertEq(amt, 500);
        address r2 = makeAddr("r2");
        vm.prank(owner);
        g.setRoyaltyReceiver(r2);
        (r, amt) = g.royaltyInfo(1, 1 ether);
        assertEq(r, r2);
        assertEq(amt, 0.05 ether);
        vm.prank(owner);
        vm.expectRevert(YoucogGhosts.ZeroAddress.selector);
        g.setRoyaltyReceiver(address(0));
    }

    function test_Interfaces() public view {
        assertTrue(g.supportsInterface(type(IERC721).interfaceId));
        assertTrue(g.supportsInterface(type(IERC2981).interfaceId));
        assertTrue(g.supportsInterface(0x5b5e139f)); // metadata
        assertTrue(g.supportsInterface(0x01ffc9a7));
        assertFalse(g.supportsInterface(0xffffffff));
    }

    // ---- traits / tokenURI / SVG
    function test_InvalidTraitsRevert() public {
        vm.startPrank(owner);
        for (uint256 s; s < 6; s++) {
            uint8[6] memory t;
            t[s] = full[s] + 1;
            vm.expectRevert(YoucogGhosts.InvalidTraits.selector);
            g.ownerMint(owner, t);
        }
        vm.stopPrank();
    }

    function test_TokenURIStructure() public {
        vm.prank(owner);
        g.ownerMint(owner, [uint8(1), 1, 1, 0, 0, 0]);
        string memory uri = g.tokenURI(1);
        assertTrue(_startsWith(uri, "data:application/json;base64,"));
        string memory json = string(Base64Decode.decode(_slice(uri, 29)));
        assertTrue(_contains(json, '"name":"Youcognito Ghost #1"'));
        assertTrue(_contains(json, '"image":"data:image/svg+xml;base64,'));
        assertTrue(_contains(json, '{"trait_type":"Hat","value":"Spy Fedora"}'));
        assertTrue(_contains(json, '{"trait_type":"Shades","value":"Spy Shades"}'));
        assertTrue(_contains(json, '{"trait_type":"Prop","value":"None"}'));
        string memory svg = g.svgOf(1);
        assertTrue(_startsWith(svg, '<svg xmlns="http://www.w3.org/2000/svg"'));
        assertTrue(_contains(svg, "</svg>"));
        vm.expectRevert();
        g.tokenURI(2);
    }

    function test_AllTraitCombosPerSlotRender() public view {
        for (uint256 s; s < 6; s++) {
            for (uint8 v; v <= full[s]; v++) {
                uint8[6] memory t;
                t[s] = v;
                string memory svg = g.previewSvg(t);
                assertTrue(bytes(svg).length > 200);
            }
        }
        string memory f = g.previewSvg(full);
        assertTrue(bytes(f).length > 200);
    }

    function test_TokenURIGasForRpc() public {
        vm.prank(owner);
        g.ownerMint(owner, full);
        uint256 g0 = gasleft();
        g.tokenURI(1);
        uint256 used = g0 - gasleft();
        emit log_named_uint("tokenURI gas (all slots)", used);
        assertLt(used, 30_000_000);
    }

    function test_WriteSampleSvg() public {
        vm.prank(owner);
        g.ownerMint(owner, [uint8(1), 1, 0, 0, 0, 0]); // default outfit from ghost-wardrobe.ts
        vm.writeFile("out-svg/ghost1.svg", g.svgOf(1));
        vm.writeFile("out-svg/ghost-full.svg", g.previewSvg(full));
        vm.writeFile("out-svg/ghost1-tokenuri.txt", g.tokenURI(1));
    }

    // ---- pause
    function test_PauseBlocksPublicNotOwnerOrTransfers() public {
        _open();
        _mintAs(_user(1));
        vm.prank(owner);
        g.pause();
        vm.expectRevert(Pausable.EnforcedPause.selector);
        _mintAs(_user(2));
        vm.prank(owner);
        g.ownerMint(owner, none);
        vm.prank(_user(1));
        g.transferFrom(_user(1), _user(3), 2); // transfers unaffected
        vm.prank(owner);
        g.unpause();
        _mintAs(_user(2));
    }

    // ---- access control
    function test_AdminFunctionsOnlyOwner() public {
        address x = _user(9);
        bytes memory err = abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, x);
        vm.startPrank(x);
        vm.expectRevert(err); g.setPrice(1);
        vm.expectRevert(err); g.setFreeUntil(1);
        vm.expectRevert(err); g.setVoucherSigner(x);
        vm.expectRevert(err); g.setRoyaltyReceiver(x);
        vm.expectRevert(err); g.pause();
        vm.expectRevert(err); g.unpause();
        vm.expectRevert(err); g.renounceOwnership();
        vm.stopPrank();
    }

    function test_RenounceDisabledAndTwoStepTransfer() public {
        vm.prank(owner);
        vm.expectRevert(YoucogGhosts.RenounceDisabled.selector);
        g.renounceOwnership();
        address n = makeAddr("newOwner");
        vm.prank(owner);
        g.transferOwnership(n);
        assertEq(g.owner(), owner);
        vm.prank(n);
        g.acceptOwnership();
        assertEq(g.owner(), n);
    }

    function test_ContractHoldsNoEth() public {
        vm.deal(address(this), 1 ether);
        (bool ok,) = address(g).call{value: 1 wei}("");
        assertFalse(ok);
    }

    // ---- vouchers
    function _sig(address minter, uint256 fid, uint256 deadline, uint256 pk) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(g.MINT_TYPEHASH(), minter, fid, deadline));
        (, string memory n, string memory v, uint256 cid, address vc,,) = g.eip712Domain();
        bytes32 ds = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(n)), keccak256(bytes(v)), cid, vc));
        (uint8 vv, bytes32 r, bytes32 s) = vm.sign(pk, keccak256(abi.encodePacked("\x19\x01", ds, structHash)));
        return abi.encodePacked(r, s, vv);
    }

    function test_VoucherGating() public {
        _open();
        vm.prank(owner);
        g.setVoucherSigner(signer);
        address u = _user(1);
        uint256 dl = block.timestamp + 1 hours;
        vm.prank(u);
        vm.expectRevert(); // no sig
        g.mint(none, 0, 42, dl, "");
        bytes memory bad = _sig(u, 42, dl, 0xB0B);
        vm.prank(u);
        vm.expectRevert(YoucogGhosts.BadVoucher.selector);
        g.mint(none, 0, 42, dl, bad);
        bytes memory sig = _sig(u, 42, dl, signerPk);
        vm.prank(_user(2)); // someone else cannot use u's voucher
        vm.expectRevert(YoucogGhosts.BadVoucher.selector);
        g.mint(none, 0, 42, dl, sig);
        vm.prank(u);
        g.mint(none, 0, 42, dl, sig);
        assertTrue(g.fidUsed(42));
        // same FID from a different wallet
        bytes memory sig2 = _sig(_user(2), 42, dl, signerPk);
        vm.prank(_user(2));
        vm.expectRevert(YoucogGhosts.FidUsed.selector);
        g.mint(none, 0, 42, dl, sig2);
        // expired
        bytes memory sig3 = _sig(_user(3), 43, dl, signerPk);
        vm.warp(dl + 1);
        vm.prank(_user(3));
        vm.expectRevert(YoucogGhosts.VoucherExpired.selector);
        g.mint(none, 0, 43, dl, sig3);
        // turning it off again opens the mint
        vm.prank(owner);
        g.setVoucherSigner(address(0));
        _mintAs(_user(3));
    }

    // ---- fuzz
    function testFuzz_TraitsRoundTrip(uint8[6] memory t) public {
        bool valid = true;
        for (uint256 s; s < 6; s++) if (t[s] > full[s]) valid = false;
        vm.prank(owner);
        if (!valid) {
            vm.expectRevert(YoucogGhosts.InvalidTraits.selector);
            g.ownerMint(owner, t);
            return;
        }
        g.ownerMint(owner, t);
        uint8[6] memory got = g.traitsOf(1);
        for (uint256 s; s < 6; s++) assertEq(got[s], t[s]);
        assertTrue(_contains(g.svgOf(1), "</svg>"));
    }

    function testFuzz_PricePaidToFaucet(uint256 p, uint256 freeUntil_, uint8 n) public {
        p = bound(p, 0, 1e30);
        freeUntil_ = bound(freeUntil_, 0, 1000);
        n = uint8(bound(n, 1, 40));
        _open();
        vm.startPrank(owner);
        g.setPrice(p);
        g.setFreeUntil(freeUntil_);
        vm.stopPrank();
        uint256 expected;
        for (uint256 i = 1; i <= n; i++) {
            address u = _user(i);
            uint256 id = g.totalSupply() + 1;
            uint256 cost = id <= freeUntil_ ? 0 : p;
            assertEq(g.currentPrice(), cost);
            tok.mint(u, cost);
            vm.startPrank(u);
            tok.approve(address(g), cost);
            g.mint(none, cost, 0, 0, "");
            vm.stopPrank();
            expected += cost;
        }
        assertEq(tok.balanceOf(faucet), expected);
        assertEq(tok.balanceOf(address(g)), 0);
    }

    function testFuzz_MaxPriceProtection(uint256 p, uint256 maxP) public {
        p = bound(p, 1, 1e30);
        maxP = bound(maxP, 0, p - 1);
        _open();
        vm.startPrank(owner);
        g.setFreeUntil(0);
        g.setPrice(p);
        vm.stopPrank();
        tok.mint(_user(1), p);
        vm.startPrank(_user(1));
        tok.approve(address(g), p);
        vm.expectRevert(abi.encodeWithSelector(YoucogGhosts.PriceAboveMax.selector, p, maxP));
        g.mint(none, maxP, 0, 0, "");
        vm.stopPrank();
    }

    function testFuzz_NonOwnerCannotAdmin(address x) public {
        vm.assume(x != owner);
        vm.prank(x);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, x));
        g.setPrice(1);
    }

    function testFuzz_RoyaltyMath(uint256 salePrice) public view {
        salePrice = bound(salePrice, 0, type(uint128).max);
        (, uint256 amt) = g.royaltyInfo(1, salePrice);
        assertEq(amt, salePrice * 500 / 10_000);
    }

    // ---- helpers
    function _startsWith(string memory a, string memory p) internal pure returns (bool) {
        bytes memory A = bytes(a); bytes memory P = bytes(p);
        if (A.length < P.length) return false;
        for (uint256 i; i < P.length; i++) if (A[i] != P[i]) return false;
        return true;
    }
    function _contains(string memory a, string memory p) internal pure returns (bool) {
        bytes memory A = bytes(a); bytes memory P = bytes(p);
        if (A.length < P.length) return false;
        for (uint256 i; i + P.length <= A.length; i++) {
            bool m = true;
            for (uint256 j; j < P.length; j++) if (A[i + j] != P[j]) { m = false; break; }
            if (m) return true;
        }
        return false;
    }
    function _slice(string memory a, uint256 from) internal pure returns (string memory) {
        bytes memory A = bytes(a); bytes memory o = new bytes(A.length - from);
        for (uint256 i; i < o.length; i++) o[i] = A[i + from];
        return string(o);
    }
}

library Base64Decode {
    function decode(string memory s) internal pure returns (bytes memory out) {
        bytes memory d = bytes(s);
        uint256 pad = d.length > 0 && d[d.length - 1] == "=" ? (d.length > 1 && d[d.length - 2] == "=" ? 2 : 1) : 0;
        out = new bytes(d.length / 4 * 3 - pad);
        uint256 o;
        for (uint256 i; i < d.length; i += 4) {
            uint256 n;
            for (uint256 j; j < 4; j++) n = (n << 6) | _v(d[i + j]);
            for (uint256 j; j < 3 && o < out.length; j++) out[o++] = bytes1(uint8(n >> (16 - 8 * j)));
        }
    }
    function _v(bytes1 c) private pure returns (uint256) {
        uint8 x = uint8(c);
        if (x >= 65 && x <= 90) return x - 65;
        if (x >= 97 && x <= 122) return x - 71;
        if (x >= 48 && x <= 57) return x + 4;
        if (x == 43) return 62;
        if (x == 47) return 63;
        return 0;
    }
}
