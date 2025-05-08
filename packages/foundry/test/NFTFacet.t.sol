// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {NFTFacet} from "../contracts/diamond/facets/NFTFacet.sol";

contract NFTFacetTest is Test {
    NFTFacet nftFacet;
    address owner = address(0xABCD);
    address user = address(0x1234);

    function setUp() public {
        nftFacet = new NFTFacet();
        nftFacet.initializeNFT("ScrumPokerBadge", "SPB");
    }

    function testInitializeNFTSetsNameAndSymbol() public {
        (string memory name, string memory symbol) = nftFacet.getBadgeData();
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

    function testIsVestedReturnsFalseInitially() public {
        assertFalse(nftFacet.isVested(user));
    }

    function testGetBadgeData() public {
        string memory userName = "Italo";
        string memory externalURI = "https://example.com/metadata.json";
        vm.prank(user);
        nftFacet.purchaseNFT(userName, externalURI);
        uint256 tokenId = nftFacet.getUserToken(user);
        (string memory name, string memory symbol) = nftFacet.getBadgeData(tokenId);
        assertEq(name, "ScrumPokerBadge");
        assertEq(symbol, "SPB");
    }

    function testGetUserTokenReturnsZeroForNonHolder() public {
        assertEq(nftFacet.getUserToken(address(0x9999)), 0);
    }
}