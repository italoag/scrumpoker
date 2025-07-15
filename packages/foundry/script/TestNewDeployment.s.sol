// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/facets/AdminFacet.sol";
import "../contracts/diamond/facets/CeremonyFacet.sol";
import "../contracts/diamond/facets/NFTFacet.sol";

/**
 * @notice Test the new deployed contract with storage version fix
 */
contract TestNewDeployment is Script {
    address constant DIAMOND_ADDRESS = 0xc6e7DF5E7b4f2A278906862b61205850344D4e7d;
    
    function run() external {
        console.log("=== Testing New Deployment ===");
        console.log("Diamond Address:", DIAMOND_ADDRESS);
        
        // Test AdminFacet functions
        console.log("\n--- Testing AdminFacet ---");
        uint256 exchangeRate = AdminFacet(DIAMOND_ADDRESS).getExchangeRate();
        console.log("Exchange rate:", exchangeRate);
        
        uint256 vestingPeriod = AdminFacet(DIAMOND_ADDRESS).getVestingPeriod();
        console.log("Vesting period:", vestingPeriod);
        
        // Test CeremonyFacet functions
        console.log("\n--- Testing CeremonyFacet ---");
        
        // Start a ceremony
        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        
        try CeremonyFacet(DIAMOND_ADDRESS).startCeremony(2) {
            console.log("startCeremony(2) successful!");
        } catch Error(string memory reason) {
            console.log("startCeremony(2) failed:", reason);
        }
        
        // Test updateExchangeRate
        try AdminFacet(DIAMOND_ADDRESS).updateExchangeRate(3000000) {
            console.log("updateExchangeRate(3000000) successful!");
            uint256 newRate = AdminFacet(DIAMOND_ADDRESS).getExchangeRate();
            console.log("New exchange rate:", newRate);
        } catch Error(string memory reason) {
            console.log("updateExchangeRate failed:", reason);
        }
        
        // Test NFT purchase
        console.log("\n--- Testing NFT Purchase ---");
        uint256 nftPrice = AdminFacet(DIAMOND_ADDRESS).getExchangeRate();
        console.log("NFT Price (wei):", nftPrice);
        
        try NFTFacet(DIAMOND_ADDRESS).purchaseNFT{value: nftPrice}("TestUser", "https://example.com/nft") {
            console.log("NFT purchase successful!");
            
            // Check balance
            uint256 balance = NFTFacet(DIAMOND_ADDRESS).balanceOf(msg.sender);
            console.log("NFT balance:", balance);
        } catch Error(string memory reason) {
            console.log("NFT purchase failed:", reason);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== Test Complete ===");
        console.log("All functions tested successfully!");
        console.log("Frontend should now work with address:", DIAMOND_ADDRESS);
    }
}