// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../facets/NFTFacet.sol";
import "./interfaces/IFacetDeployer.sol";
import "./DeployerUtils.sol";

/**
 * @title NFTFacetDeployer
 * @dev Contrato especializado para implantar a NFTFacet
 */
contract NFTFacetDeployer is IFacetDeployer {
    using DeployerUtils for address;
    
    /**
     * @dev Implanta a NFTFacet
     * @return Endereço da faceta implantada
     */
    function deployFacet() external override returns (address) {
        NFTFacet facet = new NFTFacet();
        address facetAddr = address(facet);
        require(facetAddr.isContract(), "NFTFacet deployment failed");
        return facetAddr;
    }
}
