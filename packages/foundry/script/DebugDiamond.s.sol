// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/facets/AdminFacet.sol";
import "../contracts/diamond/ScrumPokerStorage.sol";
import { ADiamondStorage } from "@solidity-lib/diamond/ADiamondStorage.sol";

/**
 * @notice Script to debug diamond facet setup and function selectors
 */
contract DebugDiamond is Script {
    function run() external view {
        // Use default anvil account (first account)
        address deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        
        // Get the diamond address from deployments
        string memory deploymentFile = string.concat(vm.projectRoot(), "/deployments/anvil.json");
        string memory json = vm.readFile(deploymentFile);
        address payable diamondAddress = payable(vm.parseJsonAddress(json, ".ScrumPokerDiamond"));
        
        console.log("=== Diamond Debug ===");
        console.log("Deployer address:", deployer);
        console.log("Diamond address:", diamondAddress);
        console.log("");
        
        // Check if diamond has code
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(diamondAddress)
        }
        console.log("Diamond code size:", codeSize);
        
        // Try to get facets using low-level call
        bytes4 facetsSelector = bytes4(keccak256("facets()"));
        (bool success, bytes memory data) = diamondAddress.staticcall(abi.encodeWithSelector(facetsSelector));
        
        if (success) {
            console.log("Facets call successful");
        } else {
            console.log("Facets call failed");
        }
        
        // Check specific function selectors
        bytes4 hasRoleSelector = AdminFacet.hasRole.selector;
        bytes4 updateExchangeRateSelector = AdminFacet.updateExchangeRate.selector;
        
        console.log("");
        console.log("hasRole selector:", vm.toString(hasRoleSelector));
        console.log("updateExchangeRate selector:", vm.toString(updateExchangeRateSelector));
        
        // Try to call hasRole directly
        (bool hasRoleSuccess,) = diamondAddress.staticcall(
            abi.encodeWithSelector(hasRoleSelector, ScrumPokerStorage.ADMIN_ROLE, deployer)
        );
        console.log("hasRole call success:", hasRoleSuccess);
        
        // Try to call updateExchangeRate (this should fail with NotAuthorized)
        (bool updateSuccess,) = diamondAddress.staticcall(
            abi.encodeWithSelector(updateExchangeRateSelector, 2000000)
        );
        console.log("updateExchangeRate call success:", updateSuccess);
        
        console.log("");
        console.log("=== Diamond Debug Complete ===");
    }
}