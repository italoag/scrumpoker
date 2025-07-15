// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/facets/AdminFacet.sol";

contract GrantAdminToUser is Script {
    function run() external {
        // Use the default deployer private key (has admin permissions)
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        
        // Diamond address from latest deployment
        address diamondAddress = 0x0165878A594ca255338adfa4d48449f69242Eb8F;
        AdminFacet adminFacet = AdminFacet(diamondAddress);
        
        // User address that needs admin permissions
        address userAddress = 0x6695EBF9b8057742faaAb700023a8ba7Cb1470a0;
        
        // Admin role
        bytes32 adminRole = keccak256("ADMIN_ROLE");
        bytes32 priceUpdaterRole = keccak256("PRICE_UPDATER_ROLE");
        
        console.log("=== Granting Admin Permissions ===");
        console.log("Diamond Address:", diamondAddress);
        console.log("User Address:", userAddress);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Grant ADMIN_ROLE to user
        adminFacet.grantRole(adminRole, userAddress);
        console.log("ADMIN_ROLE granted to user");
        
        // Grant PRICE_UPDATER_ROLE to user
        adminFacet.grantRole(priceUpdaterRole, userAddress);
        console.log("PRICE_UPDATER_ROLE granted to user");
        
        vm.stopBroadcast();
        
        console.log("=== Permissions Granted Successfully ===");
    }
}