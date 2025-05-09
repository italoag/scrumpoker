// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IFacetDeployer
 * @dev Interface para todos os deployers de facetas
 */
interface IFacetDeployer {
    /**
     * @dev Implanta uma faceta específica
     * @return Endereço da faceta implantada
     */
    function deployFacet() external returns (address);
}
