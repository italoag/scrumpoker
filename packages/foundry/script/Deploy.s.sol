//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./DeployHelper.s.sol";
import { DeployYourContract } from "./DeployYourContract.s.sol";
import { DeployScrumPokerAll } from "./DeployScrumPokerAll.s.sol";
import { DeployScrumPokerManual } from "./DeployScrumPokerManual.s.sol";

/**
 * @notice Main deployment script for all contracts
 * @dev Run this when you want to deploy multiple contracts at once
 *
 * Example: yarn deploy # runs this script(without`--file` flag)
 */
contract DeployScript is DeployHelper {
    function run() external DeployerRunner {
        // Deploys all your contracts sequentially
        // Add new deployments here when needed

        // Uncomment the deployment option you want to use
        
        // Option 1: Example contract (for testing)
        //DeployYourContract deployYourContract = new DeployYourContract();
        //deployYourContract.run();

        // Option 2: Deploy ScrumPoker using the Deployer contract (optimized)
        //DeployScrumPokerAll deployScrumPokerAll = new DeployScrumPokerAll();
        //deployScrumPokerAll.run();
        
        // Option 3: Deploy ScrumPoker manually (more control, without Deployer)
        DeployScrumPokerManual deployScrumPokerManual = new DeployScrumPokerManual();
        deployScrumPokerManual.run();
    }
}
