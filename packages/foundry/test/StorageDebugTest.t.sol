// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {AdminFacet} from "../contracts/diamond/facets/AdminFacet.sol";
import {ScrumPokerDiamond} from "../contracts/diamond/ScrumPokerDiamond.sol";
import {ScrumPokerStorage} from "../contracts/diamond/ScrumPokerStorage.sol";
import {Diamond} from "@solidity-lib/diamond/Diamond.sol";
import {OwnableDiamond} from "@solidity-lib/presets/diamond/OwnableDiamond.sol";

/**
 * @title StorageDebugTest
 * @dev Test to debug storage access patterns
 */
contract StorageDebugTest is Test {
    AdminFacet adminFacet;
    ScrumPokerDiamond scrumPokerDiamond;
    address owner = address(0xABCD);
    
    uint256 constant EXCHANGE_RATE = 0.001 ether;
    
    function setUp() public {
        adminFacet = new AdminFacet();
        scrumPokerDiamond = new ScrumPokerDiamond(owner);
        
        vm.startPrank(owner);
        
        // Add AdminFacet to Diamond
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = AdminFacet.getExchangeRate.selector;
        selectors[1] = AdminFacet.initialize.selector;
        
        Diamond.Facet[] memory facets = new Diamond.Facet[](1);
        facets[0] = Diamond.Facet({
            facetAddress: address(adminFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: selectors
        });
        
        OwnableDiamond(payable(address(scrumPokerDiamond))).diamondCut(
            facets,
            address(0),
            ""
        );
        
        vm.stopPrank();
    }
    
    function testStorageSlotConsistency() public {
        vm.startPrank(owner);
        
        // Set storage manually
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        ds.exchangeRate = EXCHANGE_RATE;
        ds.version = 2;
        
        console.log("=== After Manual Storage Setup ===");
        console.log("Direct storage exchangeRate:", ds.exchangeRate);
        console.log("Direct storage version:", ds.version);
        
        // Check via AdminFacet
        uint256 adminRate = AdminFacet(address(scrumPokerDiamond)).getExchangeRate();
        console.log("AdminFacet getExchangeRate():", adminRate);
        
        // Check storage slots directly
        bytes32 baseSlot = keccak256("scrumpoker.storage.diamond");
        uint256 versionValue;
        uint256 lastUpgradeValue;
        uint256 exchangeRateValue;
        
        assembly {
            versionValue := sload(baseSlot)
            lastUpgradeValue := sload(add(baseSlot, 1))
            exchangeRateValue := sload(add(baseSlot, 2))
        }
        
        console.log("Raw storage slot 0 (version):", versionValue);
        console.log("Raw storage slot 1 (lastUpgrade):", lastUpgradeValue);
        console.log("Raw storage slot 2 (exchangeRate):", exchangeRateValue);
        
        // Check if storage pointers are the same
        ScrumPokerStorage.DiamondStorage storage ds2 = ScrumPokerStorage.diamondStorage();
        console.log("Storage pointer 1 exchangeRate:", ds.exchangeRate);
        console.log("Storage pointer 2 exchangeRate:", ds2.exchangeRate);
        
        vm.stopPrank();
    }
    
    function testAdminFacetDirectCall() public {
        vm.startPrank(owner);
        
        // Set storage manually
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        ds.exchangeRate = EXCHANGE_RATE;
        ds.version = 2;
        
        console.log("=== Testing Direct AdminFacet Call ===");
        
        // Call AdminFacet directly (not through diamond)
        uint256 directRate = adminFacet.getExchangeRate();
        console.log("Direct AdminFacet call:", directRate);
        
        // Call AdminFacet through diamond
        uint256 diamondRate = AdminFacet(address(scrumPokerDiamond)).getExchangeRate();
        console.log("Diamond AdminFacet call:", diamondRate);
        
        vm.stopPrank();
    }
    
    function testDirectFunctionCall() public {
        vm.startPrank(owner);
        
        // Set storage manually
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        ds.exchangeRate = EXCHANGE_RATE;
        ds.version = 2;
        
        console.log("=== Testing Function Call Methods ===");
        
        // Test 1: Direct low-level call to diamond
        bytes memory callData = abi.encodeWithSelector(AdminFacet.getExchangeRate.selector);
        (bool success, bytes memory result) = address(scrumPokerDiamond).call(callData);
        
        console.log("Low-level call success:", success);
        if (success && result.length >= 32) {
            uint256 lowLevelResult = abi.decode(result, (uint256));
            console.log("Low-level call result:", lowLevelResult);
        }
        
        // Test 2: Check if selector is registered
        bytes4 selector = AdminFacet.getExchangeRate.selector;
        console.log("getExchangeRate selector:", uint32(selector));
        
        // Test 3: Call through interface
        try AdminFacet(address(scrumPokerDiamond)).getExchangeRate() returns (uint256 rate) {
            console.log("Interface call result:", rate);
        } catch Error(string memory reason) {
            console.log("Interface call failed:", reason);
        } catch {
            console.log("Interface call failed with unknown error");
        }
        
        vm.stopPrank();
    }
}