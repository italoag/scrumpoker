// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../facets/AdminFacet.sol";
import "./interfaces/IFacetDeployer.sol";
import "./DeployerUtils.sol";

/**
 * @title AdminFacetDeployer
 * @dev Contrato especializado para implantar a AdminFacet
 */
contract AdminFacetDeployer is IFacetDeployer {
    using DeployerUtils for address;
    
    /**
     * @dev Implanta a AdminFacet
     * @return Endereço da faceta implantada
     */
    function deployFacet() external override returns (address) {
        AdminFacet facet = new AdminFacet();
        address facetAddr = address(facet);
        require(facetAddr.isContract(), "AdminFacet deployment failed");
        return facetAddr;
    }
}
