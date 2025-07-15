// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../../facets/NFTFacet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title NFTFacetSelectors
 * @dev Biblioteca para obter os seletores da NFTFacet
 */
library NFTFacetSelectors {
    /**
     * @dev Retorna todos os seletores da NFTFacet
     * @return Array de seletores como bytes4[]
     */
    function getSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](20);
        // NFTFacet specific functions
        selectors[0] = NFTFacet.initializeNFT.selector;
        selectors[1] = NFTFacet.purchaseNFT.selector;
        selectors[2] = NFTFacet.withdrawFunds.selector;
        selectors[3] = NFTFacet.getBadgeData.selector;
        selectors[4] = NFTFacet.getUserToken.selector;
        selectors[5] = NFTFacet.isVested.selector;
        selectors[6] = NFTFacet.updateBadgeForSprint.selector;
        selectors[7] = NFTFacet.refundNFT.selector;
        
        // ERC721 functions using interface
        selectors[8] = IERC721.balanceOf.selector;
        selectors[9] = IERC721.ownerOf.selector;
        selectors[10] = bytes4(keccak256("name()"));
        selectors[11] = bytes4(keccak256("symbol()"));
        selectors[12] = bytes4(keccak256("tokenURI(uint256)"));
        selectors[13] = IERC721.approve.selector;
        selectors[14] = IERC721.getApproved.selector;
        selectors[15] = IERC721.setApprovalForAll.selector;
        selectors[16] = IERC721.isApprovedForAll.selector;
        selectors[17] = IERC721.transferFrom.selector;
        
        // Additional ERC721 functions
        selectors[18] = bytes4(keccak256("totalSupply()"));
        selectors[19] = bytes4(keccak256("supportsInterface(bytes4)"));
        
        return selectors;
    }
}
