// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/ScrumPokerStorage.sol";

contract CheckStorageState is Script {
    function run() external view {
        // Diamond address from latest deployment
        address diamondAddress = 0x0165878A594ca255338adfa4d48449f69242Eb8F;
        
        console.log("=== Checking Storage State ===");
        console.log("Diamond Address:", diamondAddress);
        
        // We need to use the diamond storage slot directly
        // ScrumPokerStorage.DIAMOND_STORAGE_POSITION is the slot
        bytes32 slot = ScrumPokerStorage.DIAMOND_STORAGE_POSITION;
        
        console.log("Storage slot:", vm.toString(slot));
        
        // Read the version from storage
        uint256 version = uint256(vm.load(diamondAddress, slot));
        console.log("Version from storage:", version);
        
        // Check if storage is initialized
        if (version == 0) {
            console.log("Storage is NOT initialized");
        } else {
            console.log("Storage is initialized with version:", version);
        }
        
        // Check exchange rate (offset 1)
        bytes32 exchangeRateSlot = bytes32(uint256(slot) + 1);
        uint256 exchangeRate = uint256(vm.load(diamondAddress, exchangeRateSlot));
        console.log("Exchange Rate:", exchangeRate);
        
        // Check vesting period (offset 2)
        bytes32 vestingPeriodSlot = bytes32(uint256(slot) + 2);
        uint256 vestingPeriod = uint256(vm.load(diamondAddress, vestingPeriodSlot));
        console.log("Vesting Period:", vestingPeriod);
        
        // Check paused state (offset 3)
        bytes32 pausedSlot = bytes32(uint256(slot) + 3);
        bool paused = vm.load(diamondAddress, pausedSlot) != 0;
        console.log("Paused:", paused);
        
        console.log("=== End Check ===");
    }
}