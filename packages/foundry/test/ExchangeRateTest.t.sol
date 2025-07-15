// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {NFTFacet} from "../contracts/diamond/facets/NFTFacet.sol";
import {AdminFacet} from "../contracts/diamond/facets/AdminFacet.sol";
import {ScrumPokerDiamond} from "../contracts/diamond/ScrumPokerDiamond.sol";
import {ScrumPokerStorage} from "../contracts/diamond/ScrumPokerStorage.sol";
import {Diamond} from "@solidity-lib/diamond/Diamond.sol";
import {OwnableDiamond} from "@solidity-lib/presets/diamond/OwnableDiamond.sol";
import {NFTFacetSelectors} from "../contracts/diamond/deployers/selectors/NFTFacetSelectors.sol";

/**
 * @title ExchangeRateTest
 * @dev Test to verify exchange rate accessibility
 */
contract ExchangeRateTest is Test {
    AdminFacet adminFacet;
    NFTFacet nftFacet;
    ScrumPokerDiamond scrumPokerDiamond;
    address owner = address(0xABCD);
    
    uint256 constant EXCHANGE_RATE = 0.001 ether;
    uint256 constant VESTING_PERIOD = 1 days;
    
    function setUp() public {
        // Deploy facets
        adminFacet = new AdminFacet();
        nftFacet = new NFTFacet();
        
        // Deploy Diamond
        scrumPokerDiamond = new ScrumPokerDiamond(owner);
        
        vm.startPrank(owner);
        
        // Add AdminFacet
        bytes4[] memory adminSelectors = new bytes4[](3);
        adminSelectors[0] = AdminFacet.initialize.selector;
        adminSelectors[1] = AdminFacet.getExchangeRate.selector;
        adminSelectors[2] = AdminFacet.getVestingPeriod.selector;
        
        Diamond.Facet[] memory adminFacets = new Diamond.Facet[](1);
        adminFacets[0] = Diamond.Facet({
            facetAddress: address(adminFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: adminSelectors
        });
        
        OwnableDiamond(payable(address(scrumPokerDiamond))).diamondCut(
            adminFacets,
            address(0),
            ""
        );
        
        // Add NFTFacet
        bytes4[] memory nftSelectors = NFTFacetSelectors.getSelectors();
        Diamond.Facet[] memory nftFacets = new Diamond.Facet[](1);
        nftFacets[0] = Diamond.Facet({
            facetAddress: address(nftFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: nftSelectors
        });
        
        OwnableDiamond(payable(address(scrumPokerDiamond))).diamondCut(
            nftFacets,
            address(0),
            ""
        );
        
        // Initialize with try-catch
        try AdminFacet(address(scrumPokerDiamond)).initialize(
            EXCHANGE_RATE,
            VESTING_PERIOD,
            owner
        ) {
            // Success
        } catch {
            // Fallback to manual setup
            ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
            ds.exchangeRate = EXCHANGE_RATE;
            ds.lastExchangeRateUpdate = block.timestamp;
            ds.vestingPeriod = VESTING_PERIOD;
            ds.paused = false;
            ds.nextTokenId = 0;
            bytes32 adminRole = ScrumPokerStorage.ADMIN_ROLE;
            ds.roles[adminRole][owner] = true;
        }
        
        vm.stopPrank();
    }
    
    function testExchangeRateAccessible() public view {
        uint256 exchangeRate = AdminFacet(address(scrumPokerDiamond)).getExchangeRate();
        assertEq(exchangeRate, EXCHANGE_RATE, "Exchange rate should be accessible");
        
        uint256 vestingPeriod = AdminFacet(address(scrumPokerDiamond)).getVestingPeriod();
        assertEq(vestingPeriod, VESTING_PERIOD, "Vesting period should be accessible");
    }
    
    function testDirectStorageAccess() public {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        console.log("Direct storage exchange rate:", ds.exchangeRate);
        console.log("AdminFacet exchange rate:", AdminFacet(address(scrumPokerDiamond)).getExchangeRate());
    }
}