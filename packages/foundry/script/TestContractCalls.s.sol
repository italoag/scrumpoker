// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

interface IScrumPokerDiamond {
    function getExchangeRate() external view returns (uint256);
    function getVestingPeriod() external view returns (uint256);
    function isPaused() external view returns (bool);
}

contract TestContractCalls is Script {
    function run() external view {
        // Contract address from deployment
        address diamondAddress = 0x1121cBFfCEC885F26754d891f0f956045D1E3988;
        
        IScrumPokerDiamond diamond = IScrumPokerDiamond(diamondAddress);
        
        console.log("=== Testing Contract Calls ===");
        console.log("Diamond address:", diamondAddress);
        
        // Test getExchangeRate
        uint256 exchangeRate = diamond.getExchangeRate();
        console.log("Exchange Rate:", exchangeRate);
        
        // Test getVestingPeriod
        uint256 vestingPeriod = diamond.getVestingPeriod();
        console.log("Vesting Period:", vestingPeriod);
        
        // Test isPaused
        bool paused = diamond.isPaused();
        console.log("Is Paused:", paused);
        
        console.log("=== All calls successful ===");
    }
}