// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {GhostData} from "./GhostData.sol";

/// @notice Pure on-chain renderer for the 32x32 pixel ghost. Internal library: it is inlined into
///         YoucogGhosts, so there is one contract to deploy and nothing to link.
library GhostRenderer {
    using Strings for uint256;

    uint256 internal constant SLOTS = 6; // 0 hat, 1 shades, 2 skin, 3 aura, 4 trail, 5 prop

    /// @dev Number of options per slot (0 = empty / default). Mirrors ghost-wardrobe.ts @22c3bca.
    function slotCount(uint256 slot) internal pure returns (uint256) {
        return [uint256(9), 7, 6, 5, 5, 6][slot];
    }

    function slotName(uint256 slot) internal pure returns (string memory) {
        return ["Hat", "Shades", "Sheet", "Aura", "Trail", "Prop"][slot];
    }

    function itemName(uint256 slot, uint256 v) internal pure returns (string memory) {
        if (v == 0) return slot == 2 ? "Classic Sheet" : "None";
        v -= 1;
        if (slot == 0) return ["Spy Fedora", "Red Fedora", "Gold Fedora", "Beanie", "Top Hat", "Pixel Crown", "Backwards Cap", "Propeller Cap", "Party Cone"][v];
        if (slot == 1) return ["Spy Shades", "Laser Visor", "Ice Visor", "Heart Shades", "3D Glasses", "Monocle", "Deal-With-It"][v];
        if (slot == 2) return ["Classic Sheet", "Mint Sheet", "Lilac Sheet", "Trench Coat", "Tuxedo", "Glitch Sheet"][v];
        if (slot == 3) return ["Blue Glow", "Gold Glow", "Fire Ring", "Sparkles", "Base Halo"][v];
        if (slot == 4) return ["Mist Trail", "Rainbow Trail", "Coin Trail", "Code Trail", "Flame Trail"][v];
        return ["Briefcase", "Coffee", "Balloon", "Laptop", "Magic Wand", "Rubber Duck"][v];
    }

    function _u16(bytes memory b, uint256 i) private pure returns (uint256) {
        return (uint256(uint8(b[i])) << 8) | uint8(b[i + 1]);
    }

    function _layer(uint256 idx) private pure returns (bytes memory out) {
        bytes memory off = GhostData.OFFSETS;
        bytes memory r = GhostData.RECTS;
        bytes memory pal = GhostData.PALETTE;
        uint256 s = _u16(off, idx * 2);
        uint256 e = _u16(off, idx * 2 + 2);
        bytes16 hx = "0123456789abcdef";
        for (uint256 i = s; i < e; i += 5) {
            uint256 c = uint8(r[i + 4]) * 3;
            bytes memory col = new bytes(6);
            for (uint256 k; k < 3; ++k) {
                uint8 v = uint8(pal[c + k]);
                col[2 * k] = hx[v >> 4];
                col[2 * k + 1] = hx[v & 15];
            }
            out = abi.encodePacked(
                out,
                '<rect x="', uint256(uint8(r[i])).toString(),
                '" y="', uint256(uint8(r[i + 1])).toString(),
                '" width="', uint256(uint8(r[i + 2])).toString(),
                '" height="', uint256(uint8(r[i + 3])).toString(),
                '" fill="#', col, '"/>'
            );
        }
    }

    function svg(uint8[6] memory t) internal pure returns (string memory) {
        bytes memory b = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="512" height="512" shape-rendering="crispEdges">',
            '<rect width="32" height="32" fill="#101024"/>'
        );
        if (t[3] != 0) b = abi.encodePacked(b, _layer(GhostData.AURA + t[3] - 1));
        if (t[4] != 0) b = abi.encodePacked(b, _layer(GhostData.TRAIL + t[4] - 1));
        b = abi.encodePacked(b, _layer(GhostData.BODY + t[2]));
        b = abi.encodePacked(b, t[1] == 0 ? _layer(GhostData.EYES) : _layer(GhostData.SHADES + t[1] - 1));
        if (t[0] != 0) b = abi.encodePacked(b, _layer(GhostData.HAT + t[0] - 1));
        if (t[5] != 0) b = abi.encodePacked(b, _layer(GhostData.PROP + t[5] - 1));
        return string(abi.encodePacked(b, "</svg>"));
    }

    function tokenURI(uint256 id, uint8[6] memory t) internal pure returns (string memory) {
        bytes memory attrs;
        for (uint256 s; s < SLOTS; ++s) {
            attrs = abi.encodePacked(attrs, s == 0 ? "" : ",", '{"trait_type":"', slotName(s), '","value":"', itemName(s, t[s]), '"}');
        }
        bytes memory json = abi.encodePacked(
            '{"name":"Youcognito Ghost #', id.toString(),
            '","description":"1 of 1,000 Youcognito spy ghosts on Base. Art is generated and stored fully on-chain.",',
            '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg(t))),
            '","attributes":[', attrs, "]}"
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }
}
