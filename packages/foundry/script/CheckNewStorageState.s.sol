// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/facets/AdminFacet.sol";

contract CheckNewStorageState is Script {
    function run() external view {
        // New Diamond address
        address diamondAddress = 0x65093117a463E57BfB36A03346AB6f9bbA8177D2;
        AdminFacet adminFacet = AdminFacet(diamondAddress);
        
        // Expected user address
        address user = 0x6695EBF9b8057742faaAb700023a8ba7Cb1470a0;
        
        // Admin role
        bytes32 adminRole = keccak256("ADMIN_ROLE");
        
        console.log("=== Checking New Storage State ===");
        console.log("Diamond Address:", diamondAddress);
        console.log("User Address:", user);
        
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
        try adminFacet.hasRole(adminRole, user) returns (bool hasAdmin) {
            console.log("User has ADMIN_ROLE:", hasAdmin);
        } catch {
            console.log("ERROR: Failed to check admin role");
        }
        
        console.log("=== End Check ===");
    }
}