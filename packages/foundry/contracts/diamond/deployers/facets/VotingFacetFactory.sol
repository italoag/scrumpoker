// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../../facets/VotingFacet.sol";

/**
 * @title VotingFacetFactory
 * @dev Factory especializada para criação da VotingFacet
 */
contract VotingFacetFactory {
    /**
     * @dev Deploy minimalista da VotingFacet
     * @return Endereço da faceta criada
     */
    function deployFacet() external returns (address) {
        return address(new VotingFacet());
    }
}
