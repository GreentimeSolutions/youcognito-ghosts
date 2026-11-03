// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {YoucogGhosts} from "../src/YoucogGhosts.sol";

/// Runs against a Base mainnet fork (read-only, local). FORK_URL=https://mainnet.base.org forge test --mc ForkTest
contract ForkTest is Test {
    address constant YOUCOG = 0x92Bff5D88157114DfC4a0A00F3496AA7e2E7EbA3; // faucet.server.ts TOKEN
    address constant FAUCET = 0x3067ab541253746AB353b842Fdc0970ffBDe13c7; // holder.server.ts FAUCET_WALLET

    function test_ForkRealYoucogPaymentToFaucet() public {
        string memory url = vm.envOr("FORK_URL", string(""));
        if (bytes(url).length == 0) return;
        vm.createSelectFork(url);
        address owner = makeAddr("ycg-fork-owner-7f3a");
        YoucogGhosts g = new YoucogGhosts(owner, FAUCET, owner, YOUCOG);
        assertLt(address(g).code.length, 24_577);
        uint8[6] memory t;
        vm.startPrank(owner);
        g.ownerMint(owner, t);
        g.setFreeUntil(1);
        g.setPrice(840e18);
        g.unpause();
        vm.stopPrank();
        address u = makeAddr("ycg-fork-minter-91b2");
        deal(YOUCOG, u, 1000e18);
        uint256 before = IERC20(YOUCOG).balanceOf(FAUCET);
        vm.startPrank(u);
        IERC20(YOUCOG).approve(address(g), 840e18);
        g.mint(t, 840e18, 0, 0, "");
        vm.stopPrank();
        assertEq(IERC20(YOUCOG).balanceOf(FAUCET) - before, 840e18);
        assertEq(g.ownerOf(2), u);
    }
}
