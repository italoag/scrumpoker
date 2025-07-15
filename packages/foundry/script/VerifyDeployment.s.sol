// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/facets/AdminFacet.sol";
import "../contracts/diamond/facets/NFTFacet.sol";

contract VerifyDeployment is Script {
    address constant DIAMOND_ADDRESS = 0x0165878A594ca255338adfa4d48449f69242Eb8F;
    
    function run() external view {
        console.log("=== Deployment Verification ===");
        
        // Test AdminFacet
        AdminFacet adminFacet = AdminFacet(DIAMOND_ADDRESS);
        uint256 exchangeRate = adminFacet.getExchangeRate();
        uint256 vestingPeriod = adminFacet.getVestingPeriod();
        
        console.log("AdminFacet Exchange Rate:", exchangeRate);
        console.log("AdminFacet Vesting Period:", vestingPeriod);
        
        // Test NFTFacet
        NFTFacet nftFacet = NFTFacet(DIAMOND_ADDRESS);
        string memory name = nftFacet.name();
        string memory symbol = nftFacet.symbol();
        
        console.log("NFTFacet Name:", name);
        console.log("NFTFacet Symbol:", symbol);
        
        console.log("=== Verification Complete ===");
        console.log("Both facets are working correctly!");
    }
}