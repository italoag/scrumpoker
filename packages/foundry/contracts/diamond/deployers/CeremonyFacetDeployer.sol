// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../facets/CeremonyFacet.sol";
import "./interfaces/IFacetDeployer.sol";
import "./DeployerUtils.sol";

/**
 * @title CeremonyFacetDeployer
 * @dev Contrato especializado para implantar a CeremonyFacet
 */
contract CeremonyFacetDeployer is IFacetDeployer {
    using DeployerUtils for address;
    
    /**
     * @dev Implanta a CeremonyFacet
     * @return Endereço da faceta implantada
     */
    function deployFacet() external override returns (address) {
        CeremonyFacet facet = new CeremonyFacet();
        address facetAddr = address(facet);
        require(facetAddr.isContract(), "CeremonyFacet deployment failed");
        return facetAddr;
    }
}
