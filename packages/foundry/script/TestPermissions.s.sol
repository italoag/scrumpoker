// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/facets/AdminFacet.sol";

contract TestPermissions is Script {
    function run() external view {
        // Diamond address from latest deployment
        address diamondAddress = 0x0165878A594ca255338adfa4d48449f69242Eb8F;
        AdminFacet adminFacet = AdminFacet(diamondAddress);
        
        // Expected deployer address
        address deployer = 0x6695EBF9b8057742faaAb700023a8ba7Cb1470a0;
        
        // Admin role
        bytes32 adminRole = keccak256("ADMIN_ROLE");
        
        console.log("=== Testing Permissions ===");
        console.log("Diamond Address:", diamondAddress);
        console.log("Deployer Address:", deployer);
        
        // Test basic functions
        try adminFacet.getExchangeRate() returns (uint256 rate) {
            console.log("Exchange Rate:", rate);
        } catch {
            console.log("ERROR: Failed to get exchange rate");
        }
        
        try adminFacet.getVestingPeriod() returns (uint256 period) {
            console.log("Vesting Period:", period);
        } catch {
            console.log("ERROR: Failed to get vesting period");
        }
        
        try adminFacet.isPaused() returns (bool paused) {
            console.log("Is Paused:", paused);
        } catch {
            console.log("ERROR: Failed to check if paused");
        }
        
        // Test role permissions
        try adminFacet.hasRole(adminRole, deployer) returns (bool hasAdmin) {
            console.log("Deployer has ADMIN_ROLE:", hasAdmin);
        } catch {
            console.log("ERROR: Failed to check admin role");
        }
        
        console.log("=== End Test ===");
    }
}