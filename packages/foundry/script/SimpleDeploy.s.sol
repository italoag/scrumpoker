// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
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
 * @notice Simple deployment script to debug initialization issues
 */
contract SimpleDeploy is Script {
    function run() external {
        // Use anvil private key directly
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Simple Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy facets
        AdminFacet adminFacet = new AdminFacet();
        NFTFacet nftFacet = new NFTFacet();
        CeremonyFacet ceremonyFacet = new CeremonyFacet();
        VotingFacet votingFacet = new VotingFacet();
        
        console.log("AdminFacet deployed at:", address(adminFacet));
        console.log("NFTFacet deployed at:", address(nftFacet));
        console.log("CeremonyFacet deployed at:", address(ceremonyFacet));
        console.log("VotingFacet deployed at:", address(votingFacet));
        
        // Prepare facet cuts
        Diamond.Facet[] memory facets = new Diamond.Facet[](4);
        
        facets[0] = Diamond.Facet({
            facetAddress: address(adminFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: AdminFacetSelectors.getSelectors()
        });
        
        facets[1] = Diamond.Facet({
            facetAddress: address(nftFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: NFTFacetSelectors.getSelectors()
        });
        
        facets[2] = Diamond.Facet({
            facetAddress: address(ceremonyFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: CeremonyFacetSelectors.getSelectors()
        });
        
        facets[3] = Diamond.Facet({
            facetAddress: address(votingFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: VotingFacetSelectors.getSelectors()
        });
        
        // Deploy Diamond
        ScrumPokerDiamond diamond = new ScrumPokerDiamond(deployer);
        console.log("Diamond deployed at:", address(diamond));
        
        // Add facets
        OwnableDiamond(payable(address(diamond))).diamondCut(facets, address(0), "");
        console.log("Facets added to Diamond");
        
        // Initialize AdminFacet
        console.log("Initializing AdminFacet...");
        try AdminFacet(address(diamond)).initialize(
            1000000, // initialExchangeRate
            30 days, // vestingPeriod
            deployer // admin
        ) {
            console.log("AdminFacet initialization successful");
        } catch Error(string memory reason) {
            console.log("AdminFacet initialization failed:", reason);
        }
        
        // Initialize other facets
        console.log("Initializing NFTFacet...");
        try NFTFacet(address(diamond)).initializeNFT("ScrumPoker NFT", "SCRUM") {
            console.log("NFTFacet initialization successful");
        } catch Error(string memory reason) {
            console.log("NFTFacet initialization failed:", reason);
        }
        
        console.log("Initializing CeremonyFacet...");
        try CeremonyFacet(address(diamond)).initializeCeremony() {
            console.log("CeremonyFacet initialization successful");
        } catch Error(string memory reason) {
            console.log("CeremonyFacet initialization failed:", reason);
        }
        
        console.log("Initializing VotingFacet...");
        try VotingFacet(address(diamond)).initializeVoting() {
            console.log("VotingFacet initialization successful");
        } catch Error(string memory reason) {
            console.log("VotingFacet initialization failed:", reason);
        }
        
        // Test the deployment
        console.log("");
        console.log("Testing deployment...");
        
        uint256 exchangeRate = AdminFacet(address(diamond)).getExchangeRate();
        console.log("Exchange rate:", exchangeRate);
        
        bool hasAdminRole = AdminFacet(address(diamond)).hasRole(keccak256("ADMIN_ROLE"), deployer);
        console.log("Deployer has ADMIN_ROLE:", hasAdminRole);
        
        bool hasPriceUpdaterRole = AdminFacet(address(diamond)).hasRole(keccak256("PRICE_UPDATER_ROLE"), deployer);
        console.log("Deployer has PRICE_UPDATER_ROLE:", hasPriceUpdaterRole);
        
        if (hasPriceUpdaterRole) {
            console.log("Testing updateExchangeRate...");
            try AdminFacet(address(diamond)).updateExchangeRate(2000000) {
                console.log("updateExchangeRate successful!");
                uint256 newRate = AdminFacet(address(diamond)).getExchangeRate();
                console.log("New exchange rate:", newRate);
            } catch Error(string memory reason) {
                console.log("updateExchangeRate failed:", reason);
            }
        }
        
        vm.stopBroadcast();
        
        console.log("=== Deployment Complete ===");
        console.log("Diamond Address:", address(diamond));
    }
}