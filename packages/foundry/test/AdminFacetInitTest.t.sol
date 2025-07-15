// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {AdminFacet} from "../contracts/diamond/facets/AdminFacet.sol";
import {ScrumPokerDiamond} from "../contracts/diamond/ScrumPokerDiamond.sol";
import {Diamond} from "@solidity-lib/diamond/Diamond.sol";
import {OwnableDiamond} from "@solidity-lib/presets/diamond/OwnableDiamond.sol";

/**
 * @title AdminFacetInitTest
 * @dev Test to isolate AdminFacet initialization issue
 */
contract AdminFacetInitTest is Test {
    AdminFacet adminFacet;
    ScrumPokerDiamond scrumPokerDiamond;
    address owner = address(0xABCD);
    
    uint256 constant EXCHANGE_RATE = 0.001 ether;
    uint256 constant VESTING_PERIOD = 1 days;
    
    function setUp() public {
        // Deploy AdminFacet
        adminFacet = new AdminFacet();
        
        // Deploy Diamond
        scrumPokerDiamond = new ScrumPokerDiamond(owner);
        
        vm.startPrank(owner);
        
        // Add AdminFacet to Diamond with minimal selectors
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = AdminFacet.initialize.selector;
        selectors[1] = AdminFacet.getExchangeRate.selector;
        selectors[2] = AdminFacet.getVestingPeriod.selector;
        
        Diamond.Facet[] memory facets = new Diamond.Facet[](1);
        facets[0] = Diamond.Facet({
            facetAddress: address(adminFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: selectors
        });
        
        // Add facet to diamond
        OwnableDiamond(payable(address(scrumPokerDiamond))).diamondCut(
            facets,
            address(0),
            ""
        );
        
        vm.stopPrank();
    }
    
    function testInitializeAdminFacet() public {
        vm.prank(owner);
        
        // Initialize AdminFacet through diamond
        AdminFacet(address(scrumPokerDiamond)).initialize(
            EXCHANGE_RATE,
            VESTING_PERIOD,
            owner
        );
        
        // Verify initialization worked
        uint256 exchangeRate = AdminFacet(address(scrumPokerDiamond)).getExchangeRate();
        assertEq(exchangeRate, EXCHANGE_RATE, "Exchange rate should be set correctly");
        
        uint256 vestingPeriod = AdminFacet(address(scrumPokerDiamond)).getVestingPeriod();
        assertEq(vestingPeriod, VESTING_PERIOD, "Vesting period should be set correctly");
    }
}