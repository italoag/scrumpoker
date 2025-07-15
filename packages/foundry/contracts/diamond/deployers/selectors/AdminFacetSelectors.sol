// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../../facets/AdminFacet.sol";

/**
 * @title AdminFacetSelectors
 * @dev Biblioteca para obter os seletores da AdminFacet
 */
library AdminFacetSelectors {
    /**
     * @dev Retorna todos os seletores da AdminFacet
     * @return Array de seletores como bytes4[]
     */
    function getSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](15);
        selectors[0] = AdminFacet.initialize.selector;
        selectors[1] = AdminFacet.pause.selector;
        selectors[2] = AdminFacet.unpause.selector;
        selectors[3] = AdminFacet.isPaused.selector;
        selectors[4] = AdminFacet.withdrawFunds.selector;
        selectors[5] = AdminFacet.withdrawERC20.selector;
        selectors[6] = AdminFacet.grantRole.selector;
        selectors[7] = AdminFacet.revokeRole.selector;
        selectors[8] = AdminFacet.hasRole.selector;
        selectors[9] = AdminFacet.getExchangeRate.selector;
        selectors[10] = AdminFacet.getVestingPeriod.selector;
        selectors[11] = AdminFacet.updateExchangeRate.selector;
        selectors[12] = AdminFacet.updateVestingPeriod.selector;
        selectors[13] = AdminFacet.updateExchangeRateFromOracle.selector;
        selectors[14] = AdminFacet.setPriceOracle.selector;
        return selectors;
    }
}
