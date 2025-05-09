// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../../facets/AdminFacet.sol";

/**
 * @title AdminFacetFactory
 * @dev Factory especializada para criação da AdminFacet
 */
contract AdminFacetFactory {
    /**
     * @dev Deploy minimalista da AdminFacet
     * @return Endereço da faceta criada
     */
    function deployFacet() external returns (address) {
        return address(new AdminFacet());
    }
}
