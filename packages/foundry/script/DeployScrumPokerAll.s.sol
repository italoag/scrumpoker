// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./DeployHelpers.s.sol";
import "../contracts/diamond/ScrumPokerDeployer.sol";

/**
 * @notice Deploy script for ScrumPoker contracts using the ScrumPokerDeployer
 * @dev This script deploys all facets and the Diamond in a single transaction
 *      using the optimized ScrumPokerDeployer contract
 * Example:
 * yarn deploy --file DeployScrumPokerAll.s.sol  # local anvil chain
 * yarn deploy --file DeployScrumPokerAll.s.sol --network polygon # live network (requires keystore)
 */
contract DeployScrumPokerAll is ScaffoldETHDeploy {
    /**
     * @dev Deployer setup based on `ETH_KEYSTORE_ACCOUNT` in `.env`
     * Note: Must use ScaffoldEthDeployerRunner modifier to:
     *      - Setup correct `deployer` account and fund it
     *      - Export contract addresses & ABIs to `nextjs` packages
     */
    function run() external ScaffoldEthDeployerRunner {
        // Deploy the ScrumPokerDeployer contract
        ScrumPokerDeployer scrumDeployer = new ScrumPokerDeployer();
        console.log("ScrumPokerDeployer deployed at:", address(scrumDeployer));

        // Deploy all ScrumPoker contracts using the deployer
        // Usamos a variável deployer herdada do ScaffoldETHDeploy como owner
        address diamondAddress = scrumDeployer.deployAll(deployer);
        console.log("ScrumPokerDiamond deployed at:", diamondAddress);
        
        // Store the addresses for verification and frontend integration
        writeDeploymentAddresses(scrumDeployer, diamondAddress);
    }
    
    /**
     * @dev Helper function to write deployment addresses to a JSON file for later reference
     */
    function writeDeploymentAddresses(ScrumPokerDeployer _deployer, address _diamondAddress) internal {
        string memory json = '{';
        json = string.concat(json, '"ScrumPokerDeployer": "', vm.toString(address(_deployer)), '",');
        json = string.concat(json, '"ScrumPokerDiamond": "', vm.toString(_diamondAddress), '"');
        json = string.concat(json, '}');
        
        // Write to file
        string memory filePath = string.concat(vm.projectRoot(), "/deployments/", getChainName(), ".json");
        vm.writeFile(filePath, json);
        console.log("Deployment addresses written to:", filePath);
    }
    
    /**
     * @dev Helper function to get the current chain name
     */
    function getChainName() internal view returns (string memory) {
        uint256 chainId = block.chainid;
        if (chainId == 1) return "mainnet";
        if (chainId == 5) return "goerli";
        if (chainId == 137) return "polygon";
        if (chainId == 80001) return "mumbai";
        if (chainId == 31337) return "anvil";
        if (chainId == 2025) return "devnet";
        return vm.toString(chainId);
    }
}
