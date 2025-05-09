// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./facets/AdminFacetFactory.sol";
import "./facets/NFTFacetFactory.sol";
import "./facets/CeremonyFacetFactory.sol";
import "./facets/VotingFacetFactory.sol";

/**
 * @title FacetDeployer
 * @dev Coordenador distribuído de fábricas de facetas para reduzir o tamanho do bytecode
 */
contract FacetDeployer {
    // Factories cacheadas para evitar redeployment
    address public immutable adminFactory;
    address public immutable nftFactory;
    address public immutable ceremonyFactory;
    address public immutable votingFactory;

    /**
     * @dev Inicializa as fábricas na construção - isso é mais eficiente em gas
     */
    constructor() {
        adminFactory = address(new AdminFacetFactory());
        nftFactory = address(new NFTFacetFactory());
        ceremonyFactory = address(new CeremonyFacetFactory());
        votingFactory = address(new VotingFacetFactory());
    }
    
    /**
     * @dev Utiliza a fábrica especializada para deploy da AdminFacet
     */
    function deployAdminFacet() external returns (address) {
        return AdminFacetFactory(adminFactory).deployFacet();
    }
    
    /**
     * @dev Utiliza a fábrica especializada para deploy da NFTFacet
     */
    function deployNFTFacet() external returns (address) {
        return NFTFacetFactory(nftFactory).deployFacet();
    }
    
    /**
     * @dev Utiliza a fábrica especializada para deploy da CeremonyFacet
     */
    function deployCeremonyFacet() external returns (address) {
        return CeremonyFacetFactory(ceremonyFactory).deployFacet();
    }
    
    /**
     * @dev Utiliza a fábrica especializada para deploy da VotingFacet
     */
    function deployVotingFacet() external returns (address) {
        return VotingFacetFactory(votingFactory).deployFacet();
    }
}
