// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/facets/AdminFacet.sol";

contract TestPermissions2 is Script {
    function run() external view {
        // Diamond address from latest deployment
        address diamondAddress = 0x0165878A594ca255338adfa4d48449f69242Eb8F;
        AdminFacet adminFacet = AdminFacet(diamondAddress);
        
        // Test both addresses
        address user = 0x6695EBF9b8057742faaAb700023a8ba7Cb1470a0;
        address actualDeployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        
        // Admin role
        bytes32 adminRole = keccak256("ADMIN_ROLE");
        
        console.log("=== Testing Permissions ===");
        console.log("Diamond Address:", diamondAddress);
        console.log("User Address:", user);
        console.log("Actual Deployer Address:", actualDeployer);
        
        // Test role permissions for both addresses
        try adminFacet.hasRole(adminRole, user) returns (bool hasAdmin) {
            console.log("User has ADMIN_ROLE:", hasAdmin);
        } catch {
            console.log("ERROR: Failed to check user admin role");
        }
        
        try adminFacet.hasRole(adminRole, actualDeployer) returns (bool hasAdmin) {
            console.log("Actual Deployer has ADMIN_ROLE:", hasAdmin);
        } catch {
            console.log("ERROR: Failed to check actual deployer admin role");
        }
        
        console.log("=== End Test ===");
    }
}