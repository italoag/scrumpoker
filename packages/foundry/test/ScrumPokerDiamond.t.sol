// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {ScrumPokerDiamond} from "../contracts/diamond/ScrumPokerDiamond.sol";

contract ScrumPokerDiamondTest is Test {
    ScrumPokerDiamond diamond;
    address owner = address(0xABCD);
    address user = address(0x1234);

    function setUp() public {
        diamond = new ScrumPokerDiamond(owner);
    }

    function testOwnerIsSet() public {
        // Adapte conforme getter de owner
        // assertEq(diamond.owner(), owner);
    }

    function testFallbackWhenPaused() public {
        // Adapte conforme lógica de pausa
        // diamond.pause();
        // (bool success, ) = address(diamond).call(abi.encodeWithSignature("someFunction()"));
        // assertFalse(success);
    }

    function testFallbackAllowsUnpause() public {
        // Adapte conforme lógica de unpause
        // diamond.pause();
        // (bool success, ) = address(diamond).call(abi.encodeWithSignature("unpause()"));
        // assertTrue(success);
    }
}