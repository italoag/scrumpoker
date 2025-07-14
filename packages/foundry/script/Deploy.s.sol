//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./DeployHelper.s.sol";
import { DeployScrumPokerOptimized } from "./DeployScrumPokerOptimized.s.sol";
import { DeployScrumPokerAll } from "./DeployScrumPokerAll.s.sol";
import { DeployScrumPokerManual } from "./DeployScrumPokerManual.s.sol";

/**
 * @notice Main deployment script for all contracts
 * @dev Run this when you want to deploy multiple contracts at once
 *
 * Example: yarn deploy # runs this script (without `--file` flag)
 * 
 * This script now defaults to the OPTIMIZED deployment strategy which provides
 * the best balance of gas efficiency, comprehensive logging, and robust error handling.
 */
contract DeployScript is DeployHelper {
    function run() external {
        // RECOMMENDED: Deploy using the optimized strategy (best for production)
        DeployScrumPokerOptimized deployScrumPokerOptimized = new DeployScrumPokerOptimized();
        deployScrumPokerOptimized.run();
        
        // Alternative deployment options (uncomment to use):
        
        // Option 1: Deploy using factory pattern (standardized, good for CI/CD)
        // DeployScrumPokerAll deployScrumPokerAll = new DeployScrumPokerAll();
        // deployScrumPokerAll.run();
        
        // Option 2: Deploy manually (maximum control, good for debugging)
        // DeployScrumPokerManual deployScrumPokerManual = new DeployScrumPokerManual();
        // deployScrumPokerManual.run();
    }
}
