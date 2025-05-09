// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./DeployHelpers.s.sol";
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
 * @notice Deploy script for ScrumPoker contracts manually without using ScrumPokerDeployer
 * @dev This script deploys each facet and the Diamond individually, providing more control
 *      over the deployment process and allowing for customization
 * Example:
 * yarn deploy --file DeployScrumPokerManual.s.sol  # local anvil chain
 * yarn deploy --file DeployScrumPokerManual.s.sol --network polygon # live network (requires keystore)
 */
contract DeployScrumPokerManual is ScaffoldETHDeploy {
    // Storage for deployed contract addresses
    address payable public diamondAddress;
    address public adminFacetAddress;
    address public nftFacetAddress;
    address public ceremonyFacetAddress;
    address public votingFacetAddress;
    address public diamondInitAddress;
    
    /**
     * @dev Deployer setup based on `ETH_KEYSTORE_ACCOUNT` in `.env`
     * Note: Must use ScaffoldEthDeployerRunner modifier to:
     *      - Setup correct `deployer` account and fund it
     *      - Export contract addresses & ABIs to `nextjs` packages
     */
    function run() external ScaffoldEthDeployerRunner {
        // Deploy each facet individually
        deployFacets();
        
        // Deploy the Diamond contract
        deployDiamond();
        
        // Initialize the Diamond
        initializeDiamond();
        
        // Store the addresses for verification and frontend integration
        writeDeploymentAddresses();
    }
    
    /**
     * @dev Deploy all facets individually
     */
    function deployFacets() internal {
        console.log("Deploying facets...");
        
        // Deploy AdminFacet
        AdminFacet adminFacet = new AdminFacet();
        adminFacetAddress = address(adminFacet);
        console.log("AdminFacet deployed at:", adminFacetAddress);
        
        // Deploy NFTFacet
        NFTFacet nftFacet = new NFTFacet();
        nftFacetAddress = address(nftFacet);
        console.log("NFTFacet deployed at:", nftFacetAddress);
        
        // Deploy CeremonyFacet
        CeremonyFacet ceremonyFacet = new CeremonyFacet();
        ceremonyFacetAddress = address(ceremonyFacet);
        console.log("CeremonyFacet deployed at:", ceremonyFacetAddress);
        
        // Deploy VotingFacet
        VotingFacet votingFacet = new VotingFacet();
        votingFacetAddress = address(votingFacet);
        console.log("VotingFacet deployed at:", votingFacetAddress);
        
        // Deploy DiamondInit
        DiamondInit diamondInit = new DiamondInit();
        diamondInitAddress = address(diamondInit);
        console.log("DiamondInit deployed at:", diamondInitAddress);
    }
    
    /**
     * @dev Deploy the Diamond contract and add facets
     */
    function deployDiamond() internal {
        console.log("Deploying Diamond...");
        
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
        console.log("ScrumPokerDiamond deployed at:", diamondAddress);
        
        // Add facets to the Diamond
        OwnableDiamond(diamondAddress).diamondCut(facets, address(0), "");
    }
    
    /**
     * @dev Initialize the Diamond with the DiamondInit contract
     */
    function initializeDiamond() internal {
        console.log("Initializing Diamond...");
        
        // Prepare initialization data
        // Note: You can customize the initialization parameters here
        bytes memory initData = abi.encodeWithSelector(
            DiamondInit.init.selector,
            "ScrumPoker NFT",
            "SCRUM"
        );
        
        // Call the diamondCut function on the diamond to initialize it
        OwnableDiamond(diamondAddress).diamondCut(
            new Diamond.Facet[](0),
            diamondInitAddress, 
            initData
        );
        
        console.log("Diamond initialized successfully");
    }
    
    /**
     * @dev Helper function to write deployment addresses to a JSON file for later reference
     */
    function writeDeploymentAddresses() internal {
        string memory json = '{';
        json = string.concat(json, '"ScrumPokerDiamond": "', vm.toString(diamondAddress), '",');
        json = string.concat(json, '"AdminFacet": "', vm.toString(adminFacetAddress), '",');
        json = string.concat(json, '"NFTFacet": "', vm.toString(nftFacetAddress), '",');
        json = string.concat(json, '"CeremonyFacet": "', vm.toString(ceremonyFacetAddress), '",');
        json = string.concat(json, '"VotingFacet": "', vm.toString(votingFacetAddress), '",');
        json = string.concat(json, '"DiamondInit": "', vm.toString(diamondInitAddress), '"');
        json = string.concat(json, '}');
        
        // Write to file
        string memory filePath = string.concat(vm.projectRoot(), "/deployments/", getChainName(), "_manual.json");
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
