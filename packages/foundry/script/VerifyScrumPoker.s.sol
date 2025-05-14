// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

/**
 * @notice Verification script for ScrumPoker contracts
 * @dev This script verifies all the deployed ScrumPoker contracts on a specific network
 * Example:
 * yarn verify --network polygon # Verify the ScrumPoker contracts on Polygon
 */
contract VerifyScrumPoker is Script {
    using stdJson for string;

    function run() external {
        // Determine which deployment to verify based on environment variable
        string memory deploymentType = vm.envOr("DEPLOYMENT_TYPE", string("auto"));
        string memory fileSuffix = "";
        
        if (keccak256(bytes(deploymentType)) == keccak256(bytes("manual"))) {
            fileSuffix = "_manual";
            console.log("Verifying manual deployment...");
        } else {
            console.log("Verifying auto deployment via ScrumPokerDeployer...");
        }

        // Load the deployment addresses
        string memory chainName = getChainName();
        string memory filePath = string.concat(vm.projectRoot(), "/deployments/", chainName, fileSuffix, ".json");
        string memory json = vm.readFile(filePath);
        
        // Verify contracts based on deployment type
        if (keccak256(bytes(deploymentType)) == keccak256(bytes("manual"))) {
            verifyManualDeployment(json);
        } else {
            verifyAutoDeployment(json);
        }
    }
    
    /**
     * @dev Verify contracts deployed via ScrumPokerDeployer
     */
    function verifyAutoDeployment(string memory json) internal {
        address scrumPokerDeployer = json.readAddress(".ScrumPokerDeployer");
        address scrumPokerDiamond = json.readAddress(".ScrumPokerDiamond");
        
        console.log("Verifying ScrumPokerDeployer at:", scrumPokerDeployer);
        verify(scrumPokerDeployer, "contracts/diamond/ScrumPokerDeployerRefactored.sol:ScrumPokerDeployerRefactored", "");
        
        console.log("Verifying ScrumPokerDiamond at:", scrumPokerDiamond);
        verify(scrumPokerDiamond, "contracts/diamond/ScrumPokerDiamond.sol:ScrumPokerDiamond", "");
    }
    
    /**
     * @dev Verify contracts deployed manually
     */
    function verifyManualDeployment(string memory json) internal {
        address scrumPokerDiamond = json.readAddress(".ScrumPokerDiamond");
        address adminFacet = json.readAddress(".AdminFacet");
        address nftFacet = json.readAddress(".NFTFacet");
        address ceremonyFacet = json.readAddress(".CeremonyFacet");
        address votingFacet = json.readAddress(".VotingFacet");
        address diamondInit = json.readAddress(".DiamondInit");
        
        console.log("Verifying AdminFacet at:", adminFacet);
        verify(adminFacet, "contracts/diamond/facets/AdminFacet.sol:AdminFacet", "");
        
        console.log("Verifying NFTFacet at:", nftFacet);
        verify(nftFacet, "contracts/diamond/facets/NFTFacet.sol:NFTFacet", "");
        
        console.log("Verifying CeremonyFacet at:", ceremonyFacet);
        verify(ceremonyFacet, "contracts/diamond/facets/CeremonyFacet.sol:CeremonyFacet", "");
        
        console.log("Verifying VotingFacet at:", votingFacet);
        verify(votingFacet, "contracts/diamond/facets/VotingFacet.sol:VotingFacet", "");
        
        console.log("Verifying DiamondInit at:", diamondInit);
        verify(diamondInit, "contracts/diamond/DiamondInit.sol:DiamondInit", "");
        
        console.log("Verifying ScrumPokerDiamond at:", scrumPokerDiamond);
        verify(scrumPokerDiamond, "contracts/diamond/ScrumPokerDiamond.sol:ScrumPokerDiamond", "");
    }
    
    /**
     * @dev Helper function to verify a contract
     */
    function verify(address contractAddress, string memory contractPath, string memory constructorArgs) internal {
        if (contractAddress.code.length == 0) {
            console.log("Contract at %s has no code. Skipping verification.", contractAddress);
            return;
        }

        // Set up verification command
        string[] memory inputs = new string[](7);
        inputs[0] = "forge";
        inputs[1] = "verify-contract";
        inputs[2] = vm.toString(contractAddress);
        inputs[3] = contractPath;
        inputs[4] = "--chain-id";
        inputs[5] = vm.toString(block.chainid);
        
        if (bytes(constructorArgs).length > 0) {
            inputs[6] = string.concat("--constructor-args ", constructorArgs);
        } else {
            inputs[6] = "--watch";
        }

        // Execute verification
        vm.ffi(inputs);
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
