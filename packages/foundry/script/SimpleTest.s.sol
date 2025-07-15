// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/facets/AdminFacet.sol";

/**
 * @notice Simple test to check if basic functions work
 */
contract SimpleTest is Script {
    function run() external view {
        // Get the diamond address from deployments
        string memory deploymentFile = string.concat(vm.projectRoot(), "/deployments/anvil.json");
        string memory json = vm.readFile(deploymentFile);
        address payable diamondAddress = payable(vm.parseJsonAddress(json, ".ScrumPokerDiamond"));
        
        console.log("=== Simple Test ===");
        console.log("Diamond address:", diamondAddress);
        
        // Test getExchangeRate function
        bytes4 getExchangeRateSelector = AdminFacet.getExchangeRate.selector;
        console.log("getExchangeRate selector:", vm.toString(getExchangeRateSelector));
        
        (bool success, bytes memory data) = diamondAddress.staticcall(
            abi.encodeWithSelector(getExchangeRateSelector)
        );
        
        if (success && data.length > 0) {
            uint256 exchangeRate = abi.decode(data, (uint256));
            console.log("Exchange rate:", exchangeRate);
        } else {
            console.log("getExchangeRate call failed");
            console.log("Success:", success);
            console.log("Data length:", data.length);
        }
        
        // Test getVestingPeriod function
        bytes4 getVestingPeriodSelector = AdminFacet.getVestingPeriod.selector;
        console.log("getVestingPeriod selector:", vm.toString(getVestingPeriodSelector));
        
        (success, data) = diamondAddress.staticcall(
            abi.encodeWithSelector(getVestingPeriodSelector)
        );
        
        if (success && data.length > 0) {
            uint256 vestingPeriod = abi.decode(data, (uint256));
            console.log("Vesting period:", vestingPeriod);
        } else {
            console.log("getVestingPeriod call failed");
        }
        
        // Test isPaused function
        bytes4 isPausedSelector = AdminFacet.isPaused.selector;
        console.log("isPaused selector:", vm.toString(isPausedSelector));
        
        (success, data) = diamondAddress.staticcall(
            abi.encodeWithSelector(isPausedSelector)
        );
        
        if (success && data.length > 0) {
            bool paused = abi.decode(data, (bool));
            console.log("Is paused:", paused);
        } else {
            console.log("isPaused call failed");
        }
        
        console.log("=== Simple Test Complete ===");
    }
}