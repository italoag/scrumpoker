// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/facets/AdminFacet.sol";
import "../contracts/diamond/ScrumPokerStorage.sol";

/**
 * @notice Script to test role assignments and updateExchangeRate function
 */
contract TestRoles is Script {
    function run() external {
        // Use default anvil account (first account)
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get the diamond address from deployments
        string memory deploymentFile = string.concat(vm.projectRoot(), "/deployments/anvil.json");
        string memory json = vm.readFile(deploymentFile);
        address payable diamondAddress = payable(vm.parseJsonAddress(json, ".ScrumPokerDiamond"));
        
        console.log("=== Role Test ===");
        console.log("Deployer address:", deployer);
        console.log("Diamond address:", diamondAddress);
        console.log("");
        
        // Check roles using direct calls
        bytes4 hasRoleSelector = AdminFacet.hasRole.selector;
        
        // Check ADMIN_ROLE
        (bool success, bytes memory data) = diamondAddress.staticcall(
            abi.encodeWithSelector(hasRoleSelector, ScrumPokerStorage.ADMIN_ROLE, deployer)
        );
        
        if (success && data.length > 0) {
            bool hasAdminRole = abi.decode(data, (bool));
            console.log("Deployer has ADMIN_ROLE:", hasAdminRole);
        } else {
            console.log("Failed to check ADMIN_ROLE");
        }
        
        // Check PRICE_UPDATER_ROLE
        (success, data) = diamondAddress.staticcall(
            abi.encodeWithSelector(hasRoleSelector, ScrumPokerStorage.PRICE_UPDATER_ROLE, deployer)
        );
        
        if (success && data.length > 0) {
            bool hasPriceUpdaterRole = abi.decode(data, (bool));
            console.log("Deployer has PRICE_UPDATER_ROLE:", hasPriceUpdaterRole);
            
            if (hasPriceUpdaterRole) {
                console.log("");
                console.log("Attempting to update exchange rate...");
                
                // Get current exchange rate
                bytes4 getExchangeRateSelector = AdminFacet.getExchangeRate.selector;
                (bool getRateSuccess, bytes memory rateData) = diamondAddress.staticcall(
                    abi.encodeWithSelector(getExchangeRateSelector)
                );
                
                if (getRateSuccess && rateData.length > 0) {
                    uint256 currentRate = abi.decode(rateData, (uint256));
                    console.log("Current exchange rate:", currentRate);
                }
                
                // Try to update exchange rate
                vm.startBroadcast(deployerPrivateKey);
                
                bytes4 updateExchangeRateSelector = AdminFacet.updateExchangeRate.selector;
                (bool updateSuccess, bytes memory updateData) = diamondAddress.call(
                    abi.encodeWithSelector(updateExchangeRateSelector, 2000000)
                );
                
                if (updateSuccess) {
                    console.log("Exchange rate update successful!");
                    
                    // Check new rate
                    (getRateSuccess, rateData) = diamondAddress.staticcall(
                        abi.encodeWithSelector(getExchangeRateSelector)
                    );
                    
                    if (getRateSuccess && rateData.length > 0) {
                        uint256 newRate = abi.decode(rateData, (uint256));
                        console.log("New exchange rate:", newRate);
                    }
                } else {
                    console.log("Exchange rate update failed");
                    if (updateData.length > 0) {
                        console.log("Error data length:", updateData.length);
                        console.logBytes(updateData);
                    }
                }
                
                vm.stopBroadcast();
            } else {
                console.log("");
                console.log("Deployer does not have PRICE_UPDATER_ROLE");
                console.log("This explains the NotAuthorized() error");
            }
        } else {
            console.log("Failed to check PRICE_UPDATER_ROLE");
        }
        
        console.log("");
        console.log("=== Role Test Complete ===");
    }
}