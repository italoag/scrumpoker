// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../../facets/CeremonyFacet.sol";

/**
 * @title CeremonyFacetFactory
 * @dev Factory especializada para criação da CeremonyFacet
 */
contract CeremonyFacetFactory {
    /**
     * @dev Deploy minimalista da CeremonyFacet
     * @return Endereço da faceta criada
     */
    function deployFacet() external returns (address) {
        return address(new CeremonyFacet());
    }
}
