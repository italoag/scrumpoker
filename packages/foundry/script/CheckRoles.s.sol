// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/facets/AdminFacet.sol";
import "../contracts/diamond/ScrumPokerStorage.sol";

/**
 * @notice Script to check role assignments and debug authorization issues
 */
contract CheckRoles is Script {
    function run() external {
        // Use default anvil account (first account)
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get the diamond address from deployments
        string memory deploymentFile = string.concat(vm.projectRoot(), "/deployments/anvil.json");
        string memory json = vm.readFile(deploymentFile);
        address diamondAddress = vm.parseJsonAddress(json, ".ScrumPokerDiamond");
        
        console.log("=== Role Check Debug ===");
        console.log("Deployer address:", deployer);
        console.log("Diamond address:", diamondAddress);
        console.log("");
        
        // Check if deployer has ADMIN_ROLE
        bool hasAdminRole = AdminFacet(diamondAddress).hasRole(ScrumPokerStorage.ADMIN_ROLE, deployer);
        console.log("Deployer has ADMIN_ROLE:", hasAdminRole);
        
        // Check if deployer has PRICE_UPDATER_ROLE
        bool hasPriceUpdaterRole = AdminFacet(diamondAddress).hasRole(ScrumPokerStorage.PRICE_UPDATER_ROLE, deployer);
        console.log("Deployer has PRICE_UPDATER_ROLE:", hasPriceUpdaterRole);
        
        // Get current exchange rate
        uint256 currentRate = AdminFacet(diamondAddress).getExchangeRate();
        console.log("Current exchange rate:", currentRate);
        
        // Try to update exchange rate if deployer has the role
        if (hasPriceUpdaterRole) {
            console.log("");
            console.log("Attempting to update exchange rate...");
            
            vm.startBroadcast(deployerPrivateKey);
            try AdminFacet(diamondAddress).updateExchangeRate(2000000) {
                console.log("Exchange rate update successful!");
                uint256 newRate = AdminFacet(diamondAddress).getExchangeRate();
                console.log("New exchange rate:", newRate);
            } catch Error(string memory reason) {
                console.log("Exchange rate update failed with reason:", reason);
            } catch {
                console.log("Exchange rate update failed with unknown error");
            }
            vm.stopBroadcast();
        } else {
            console.log("");
            console.log("Deployer does not have PRICE_UPDATER_ROLE, cannot update exchange rate");
            console.log("This explains the NotAuthorized() error");
        }
        
        console.log("");
        console.log("=== Role Check Complete ===");
    }
}