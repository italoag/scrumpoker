// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../../facets/NFTFacet.sol";

/**
 * @title NFTFacetFactory
 * @dev Factory especializada para criação da NFTFacet
 */
contract NFTFacetFactory {
    /**
     * @dev Deploy minimalista da NFTFacet
     * @return Endereço da faceta criada
     */
    function deployFacet() external returns (address) {
        return address(new NFTFacet());
    }
}
