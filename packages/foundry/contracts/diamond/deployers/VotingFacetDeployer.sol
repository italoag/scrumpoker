// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../facets/VotingFacet.sol";
import "./interfaces/IFacetDeployer.sol";
import "./DeployerUtils.sol";

/**
 * @title VotingFacetDeployer
 * @dev Contrato especializado para implantar a VotingFacet
 */
contract VotingFacetDeployer is IFacetDeployer {
    using DeployerUtils for address;
    
    /**
     * @dev Implanta a VotingFacet
     * @return Endereço da faceta implantada
     */
    function deployFacet() external override returns (address) {
        VotingFacet facet = new VotingFacet();
        address facetAddr = address(facet);
        require(facetAddr.isContract(), "VotingFacet deployment failed");
        return facetAddr;
    }
}
