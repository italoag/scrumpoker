// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../../facets/NFTFacet.sol";

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
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = NFTFacet.initializeNFT.selector;
        selectors[1] = NFTFacet.purchaseNFT.selector;
        selectors[2] = NFTFacet.withdrawFunds.selector;
        selectors[3] = NFTFacet.getBadgeData.selector;
        selectors[4] = NFTFacet.getUserToken.selector;
        selectors[5] = NFTFacet.isVested.selector;
        selectors[6] = NFTFacet.updateBadgeForSprint.selector;
        return selectors;
    }
}
