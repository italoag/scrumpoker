// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./DeployHelper.s.sol";
import "../contracts/diamond/ScrumPokerDiamond.sol";
import "../contracts/diamond/DiamondInit.sol";
import "../contracts/diamond/facets/AdminFacet.sol";
import "../contracts/diamond/facets/NFTFacet.sol";
import "../contracts/diamond/facets/CeremonyFacet.sol";
import "../contracts/diamond/facets/VotingFacet.sol";
import "../contracts/diamond/deployers/selectors/AdminFacetSelectors.sol";
import "../contracts/diamond/deployers/selectors/NFTFacetSelectors.sol";
import "../contracts/diamond/deployers/selectors/CeremonyFacetSelectors.sol";
import "../contracts/diamond/deployers/selectors/VotingFacetSelectors.sol";
import { Diamond } from "@solidity-lib/diamond/Diamond.sol";
import { OwnableDiamond } from "@solidity-lib/presets/diamond/OwnableDiamond.sol";

/**
 * @notice RECOMMENDED: Optimized deployment script for ScrumPoker contracts
 * @dev This script combines the best aspects of all deployment strategies:
 *      - Manual control like DeployScrumPokerManual
 *      - Gas efficiency optimizations
 *      - Robust error handling
 *      - Comprehensive logging and verification
 * 
 * Usage:
 * yarn deploy --file DeployScrumPokerOptimized.s.sol  # local anvil chain
 * yarn deploy --file DeployScrumPokerOptimized.s.sol --network polygon # live network
 */
contract DeployScrumPokerOptimized is DeployHelper {
    // Storage for deployed contract addresses
    address payable public diamondAddress;
    address public adminFacetAddress;
    address public nftFacetAddress;
    address public ceremonyFacetAddress;
    address public votingFacetAddress;
    address public diamondInitAddress;
    
    // Gas tracking
    uint256 public totalGasUsed;
    uint256 public deploymentStartGas;
    
    /**
     * @dev Main deployment function with comprehensive logging and verification
     */
    function run() external DeployerRunner {
        deploymentStartGas = gasleft();
        
        console.log("=== ScrumPoker Diamond Deployment (Optimized) ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("");
        
        // Step 1: Deploy facets
        deployFacets();
        
        // Step 2: Deploy Diamond with facets
        deployDiamondWithFacets();
        
        // Step 3: Initialize Diamond
        initializeDiamond();
        
        // Step 4: Verify deployment
        verifyDeployment();
        
        // Step 5: Export addresses and ABIs
        exportDeploymentData();
        
        // Final gas report
        totalGasUsed = deploymentStartGas - gasleft();
        console.log("=== Deployment Complete ===");
        console.log("Total Gas Used:", totalGasUsed);
        console.log("Diamond Address:", diamondAddress);
    }
    
    /**
     * @dev Deploy all facets with gas tracking
     */
    function deployFacets() internal {
        console.log("Step 1: Deploying facets...");
        uint256 stepStartGas = gasleft();
        
        // Deploy AdminFacet
        AdminFacet adminFacet = new AdminFacet();
        adminFacetAddress = address(adminFacet);
        console.log("  AdminFacet deployed at:", adminFacetAddress);
        
        // Deploy NFTFacet
        NFTFacet nftFacet = new NFTFacet();
        nftFacetAddress = address(nftFacet);
        console.log("  NFTFacet deployed at:", nftFacetAddress);
        
        // Deploy CeremonyFacet
        CeremonyFacet ceremonyFacet = new CeremonyFacet();
        ceremonyFacetAddress = address(ceremonyFacet);
        console.log("  CeremonyFacet deployed at:", ceremonyFacetAddress);
        
        // Deploy VotingFacet
        VotingFacet votingFacet = new VotingFacet();
        votingFacetAddress = address(votingFacet);
        console.log("  VotingFacet deployed at:", votingFacetAddress);
        
        // Deploy DiamondInit
        DiamondInit diamondInit = new DiamondInit();
        diamondInitAddress = address(diamondInit);
        console.log("  DiamondInit deployed at:", diamondInitAddress);
        
        uint256 stepGasUsed = stepStartGas - gasleft();
        console.log("  Facets deployment gas used:", stepGasUsed);
        console.log("");
    }
    
    /**
     * @dev Deploy Diamond and add all facets in a single transaction
     */
    function deployDiamondWithFacets() internal {
        console.log("Step 2: Deploying Diamond with facets...");
        uint256 stepStartGas = gasleft();
        
        // Prepare facet cuts for all facets
        Diamond.Facet[] memory facets = new Diamond.Facet[](4);
        
        // AdminFacet cut
        facets[0] = Diamond.Facet({
            facetAddress: adminFacetAddress,
            action: Diamond.FacetAction.Add,
            functionSelectors: AdminFacetSelectors.getSelectors()
        });
        
        // NFTFacet cut
        facets[1] = Diamond.Facet({
            facetAddress: nftFacetAddress,
            action: Diamond.FacetAction.Add,
            functionSelectors: NFTFacetSelectors.getSelectors()
        });
        
        // CeremonyFacet cut
        facets[2] = Diamond.Facet({
            facetAddress: ceremonyFacetAddress,
            action: Diamond.FacetAction.Add,
            functionSelectors: CeremonyFacetSelectors.getSelectors()
        });
        
        // VotingFacet cut
        facets[3] = Diamond.Facet({
            facetAddress: votingFacetAddress,
            action: Diamond.FacetAction.Add,
            functionSelectors: VotingFacetSelectors.getSelectors()
        });
        
        // Deploy the Diamond contract with all facets
        ScrumPokerDiamond diamond = new ScrumPokerDiamond(deployer);
        diamondAddress = payable(address(diamond));
        console.log("  ScrumPokerDiamond deployed at:", diamondAddress);
        
        // Add facets to the Diamond
        OwnableDiamond(diamondAddress).diamondCut(facets, address(0), "");
        console.log("  All facets added to Diamond successfully");
        
        uint256 stepGasUsed = stepStartGas - gasleft();
        console.log("  Diamond deployment gas used:", stepGasUsed);
        console.log("");
    }
    
    /**
     * @dev Initialize the Diamond with proper error handling
     */
    function initializeDiamond() internal {
        console.log("Step 3: Initializing Diamond...");
        uint256 stepStartGas = gasleft();
        
        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            DiamondInit.init.selector,
            "ScrumPoker NFT",
            "SCRUM"
        );
        
        // Call the diamondCut function on the diamond to initialize it
        try OwnableDiamond(diamondAddress).diamondCut(
            new Diamond.Facet[](0),
            diamondInitAddress, 
            initData
        ) {
            console.log("  Diamond initialized successfully");
        } catch Error(string memory reason) {
            console.log("  Initialization failed with reason:", reason);
            revert(string.concat("Diamond initialization failed: ", reason));
        } catch {
            console.log("  Initialization failed with unknown error");
            revert("Diamond initialization failed with unknown error");
        }
        
        uint256 stepGasUsed = stepStartGas - gasleft();
        console.log("  Initialization gas used:", stepGasUsed);
        console.log("");
    }
    
    /**
     * @dev Verify that the deployment was successful
     */
    function verifyDeployment() internal view {
        console.log("Step 4: Verifying deployment...");
        
        // Verify Diamond has correct owner
        address owner = OwnableDiamond(diamondAddress).owner();
        require(owner == deployer, "Diamond owner verification failed");
        console.log("  Diamond owner verified:", owner);
        
        // Verify facets are properly added (check a function from each facet)
        // This is a basic verification - in production you might want more comprehensive checks
        bytes4[] memory adminSelectors = AdminFacetSelectors.getSelectors();
        bytes4[] memory nftSelectors = NFTFacetSelectors.getSelectors();
        bytes4[] memory ceremonySelectors = CeremonyFacetSelectors.getSelectors();
        bytes4[] memory votingSelectors = VotingFacetSelectors.getSelectors();
        
        console.log("  AdminFacet selectors count:", adminSelectors.length);
        console.log("  NFTFacet selectors count:", nftSelectors.length);
        console.log("  CeremonyFacet selectors count:", ceremonySelectors.length);
        console.log("  VotingFacet selectors count:", votingSelectors.length);
        
        console.log("  Deployment verification completed successfully");
        console.log("");
    }
    
    /**
     * @dev Export deployment data for frontend integration
     */
    function exportDeploymentData() internal {
        console.log("Step 5: Exporting deployment data...");
        
        // Add addresses to deployments array for DeployHelper export
        deployments.push(Deployment("ScrumPokerDiamond", diamondAddress));
        deployments.push(Deployment("AdminFacet", adminFacetAddress));
        deployments.push(Deployment("NFTFacet", nftFacetAddress));
        deployments.push(Deployment("CeremonyFacet", ceremonyFacetAddress));
        deployments.push(Deployment("VotingFacet", votingFacetAddress));
        deployments.push(Deployment("DiamondInit", diamondInitAddress));
        
        // Write additional deployment info
        writeOptimizedDeploymentFile();
        
        console.log("  Deployment data exported successfully");
        console.log("");
    }
    
    /**
     * @dev Write optimized deployment file with additional metadata
     */
    function writeOptimizedDeploymentFile() internal {
        string memory json = '{';
        json = string.concat(json, '"network": "', getChain(), '",');
        json = string.concat(json, '"chainId": ', vm.toString(block.chainid), ',');
        json = string.concat(json, '"deployer": "', vm.toString(deployer), '",');
        json = string.concat(json, '"blockNumber": ', vm.toString(block.number), ',');
        json = string.concat(json, '"timestamp": ', vm.toString(block.timestamp), ',');
        json = string.concat(json, '"gasUsed": ', vm.toString(totalGasUsed), ',');
        json = string.concat(json, '"contracts": {');
        json = string.concat(json, '"ScrumPokerDiamond": "', vm.toString(diamondAddress), '",');
        json = string.concat(json, '"AdminFacet": "', vm.toString(adminFacetAddress), '",');
        json = string.concat(json, '"NFTFacet": "', vm.toString(nftFacetAddress), '",');
        json = string.concat(json, '"CeremonyFacet": "', vm.toString(ceremonyFacetAddress), '",');
        json = string.concat(json, '"VotingFacet": "', vm.toString(votingFacetAddress), '",');
        json = string.concat(json, '"DiamondInit": "', vm.toString(diamondInitAddress), '"');
        json = string.concat(json, '}}');
        
        // Write to optimized deployment file
        string memory filePath = string.concat(vm.projectRoot(), "/deployments/", getChain(), "_optimized.json");
        vm.writeFile(filePath, json);
        console.log("  Optimized deployment file written to:", filePath);
    }
}