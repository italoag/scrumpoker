// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {AdminFacet} from "../contracts/diamond/facets/AdminFacet.sol";
import {ScrumPokerStorage} from "../contracts/diamond/ScrumPokerStorage.sol";

contract AdminFacetTest is Test {
    AdminFacet adminFacet;
    address owner = address(0xABCD);
    address user = address(0x1234);
    uint256 initialRate = 1e18;
    uint256 vestingPeriod = 30 days;
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    function setUp() public {
        adminFacet = new AdminFacet();
        adminFacet.initialize(initialRate, vestingPeriod, owner);
    }

    function testInitializeSetsState() public {
        (uint256 rate, uint256 period, address admin) = adminFacet.getExchangeRate();
        assertEq(rate, initialRate);
        assertEq(period, vestingPeriod);
        assertEq(admin, owner);
    }

    function testUpdateExchangeRateByAdmin() public {
        vm.prank(owner);
        adminFacet.updateExchangeRate(2e18);
        (uint256 rate,,) = adminFacet.getExchangeRate();
        assertEq(rate, 2e18);
    }

    function testUpdateExchangeRateByNonAdminReverts() public {
        vm.prank(user);
        vm.expectRevert();
        adminFacet.updateExchangeRate(2e18);
    }

    function testPauseAndUnpause() public {
        vm.prank(owner);
        adminFacet.pause();
        assertTrue(ScrumPokerStorage.diamondStorage().paused);
        vm.prank(owner);
        adminFacet.unpause();
        assertFalse(ScrumPokerStorage.diamondStorage().paused);
    }

    function testGrantAndRevokeRole() public {
        vm.prank(owner);
        adminFacet.grantRole(ADMIN_ROLE, user);
        assertTrue(adminFacet.hasRole(ADMIN_ROLE, user));
        vm.prank(owner);
        adminFacet.revokeRole(ADMIN_ROLE, user);
        assertFalse(adminFacet.hasRole(ADMIN_ROLE, user));
    }

    function testSetPriceOracle() public {
        address oracle = address(0xBEEF);
        vm.prank(owner);
        adminFacet.setPriceOracle(oracle);
        // Adicione assertivas conforme implementação
    }

    function testZeroAddressReverts() public {
        vm.expectRevert();
        adminFacet.initialize(initialRate, vestingPeriod, address(0));
    }
}