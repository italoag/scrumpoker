// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../../facets/CeremonyFacet.sol";

/**
 * @title CeremonyFacetSelectors
 * @dev Biblioteca para obter os seletores da CeremonyFacet
 */
library CeremonyFacetSelectors {
    /**
     * @dev Retorna todos os seletores da CeremonyFacet
     * @return Array de seletores como bytes4[]
     */
    function getSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](9);
        selectors[0] = CeremonyFacet.initializeCeremony.selector;
        selectors[1] = CeremonyFacet.startCeremony.selector;
        selectors[2] = CeremonyFacet.requestCeremonyEntry.selector;
        selectors[3] = CeremonyFacet.approveEntry.selector;
        selectors[4] = CeremonyFacet.concludeCeremony.selector;
        selectors[5] = CeremonyFacet.getCeremony.selector;
        selectors[6] = CeremonyFacet.ceremonyExists.selector;
        selectors[7] = CeremonyFacet.hasRequestedEntry.selector;
        selectors[8] = CeremonyFacet.isApproved.selector;
        return selectors;
    }
}
