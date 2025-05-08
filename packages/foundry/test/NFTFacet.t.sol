// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {NFTFacet} from "../contracts/diamond/facets/NFTFacet.sol";
import {ScrumPokerStorage} from "../contracts/diamond/ScrumPokerStorage.sol";

contract NFTFacetTest is Test {
    NFTFacet nftFacet;
    address owner = address(0xABCD);
    address user = address(0x1234);

    function setUp() public {
        nftFacet = new NFTFacet();
        nftFacet.initializeNFT("ScrumPokerBadge", "SPB");
    }

    function testInitializeNFTSetsNameAndSymbol() public view {
        string memory name = nftFacet.name();
        string memory symbol = nftFacet.symbol();
        assertEq(name, "ScrumPokerBadge");
        assertEq(symbol, "SPB");
    }

    function testPurchaseNFT() public {
        string memory userName = "Italo";
        string memory externalURI = "https://example.com/metadata.json";
        vm.prank(user);
        nftFacet.purchaseNFT(userName, externalURI);
        uint256 tokenId = nftFacet.getUserToken(user);
        assertGt(tokenId, 0);
        assertTrue(nftFacet.isVested(user));
    }

    function testWithdrawFunds() public {
        string memory userName = "Italo";
        string memory externalURI = "https://example.com/metadata.json";
        vm.prank(user);
        nftFacet.purchaseNFT(userName, externalURI);
        uint256 balanceBefore = address(owner).balance;
        vm.prank(owner);
        nftFacet.withdrawFunds();
        uint256 balanceAfter = address(owner).balance;
        assertGt(balanceAfter, balanceBefore);
    }

    function testUpdateBadgeForSprint() public {
        string memory userName = "Italo";
        string memory externalURI = "https://example.com/metadata.json";
        vm.prank(user);
        nftFacet.purchaseNFT(userName, externalURI);
        uint256 tokenId = nftFacet.getUserToken(user);
        nftFacet.updateBadgeForSprint(user, tokenId, 1);
        assertEq(nftFacet.getUserToken(user), tokenId);
    }

    function testIsVestedReturnsFalseInitially() public view {
        assertFalse(nftFacet.isVested(user));
    }

    function testGetBadgeData() public {
        string memory userName = "Italo";
        string memory externalURI = "https://example.com/metadata.json";
        vm.prank(user);
        nftFacet.purchaseNFT(userName, externalURI);
        uint256 tokenId = nftFacet.getUserToken(user);
        
        (string memory retrievedUserName, 
         address retrievedAddress,
         uint256 ceremoniesParticipated,
         uint256 votesCast,
         ScrumPokerStorage.SprintResult[] memory sprintResults,
         string memory retrievedExternalURI) = nftFacet.getBadgeData(tokenId);
        
        assertEq(retrievedUserName, userName);
        assertEq(retrievedAddress, user);
        assertEq(ceremoniesParticipated, 0);
        assertEq(votesCast, 0);
        // Não verificamos sprintResults pois deve estar vazio inicialmente
        assertEq(retrievedExternalURI, externalURI);
    }

    function testGetUserTokenReturnsZeroForNonHolder() public view {
        assertEq(nftFacet.getUserToken(address(0x9999)), 0);
    }
}