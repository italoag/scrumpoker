// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./deployers/FacetDeployer.sol";
import "./deployers/DiamondDeployer.sol";
import "./deployers/selectors/AdminFacetSelectors.sol";
import "./deployers/selectors/NFTFacetSelectors.sol";
import "./deployers/selectors/CeremonyFacetSelectors.sol";
import "./deployers/selectors/VotingFacetSelectors.sol";
import "@solidity-lib/diamond/Diamond.sol";
import "@solidity-lib/presets/diamond/OwnableDiamond.sol";

/**
 * @title ScrumPokerDeployer
 * @dev Contrato principal para implantação do sistema ScrumPoker
 * Versão refatorada e otimizada para reduzir o tamanho do bytecode
 */
contract ScrumPokerDeployer {
    // Eventos para acompanhar as implantações
    event DeploymentCompleted(address indexed diamond, address[] facets);
    
    // Contratos auxiliares
    FacetDeployer public immutable facetDeployer;
    DiamondDeployer public immutable diamondDeployer;
    
    /**
     * @dev Construtor que implanta os contratos auxiliares
     */
    constructor() {
        facetDeployer = new FacetDeployer();
        diamondDeployer = new DiamondDeployer();
    }
    
    /**
     * @dev Implanta todo o sistema ScrumPoker
     * @param _owner Proprietário do Diamond
     * @return Endereço do Diamond implantado
     */
    function deployAll(address _owner) external returns (address) {
        // 1. Implanta todas as facetas
        address adminFacet = facetDeployer.deployAdminFacet();
        address nftFacet = facetDeployer.deployNFTFacet();
        address ceremonyFacet = facetDeployer.deployCeremonyFacet();
        address votingFacet = facetDeployer.deployVotingFacet();
        
        // 2. Obtém os seletores de cada faceta
        bytes4[][] memory allSelectors = new bytes4[][](4);
        allSelectors[0] = AdminFacetSelectors.getSelectors();
        allSelectors[1] = NFTFacetSelectors.getSelectors();
        allSelectors[2] = CeremonyFacetSelectors.getSelectors();
        allSelectors[3] = VotingFacetSelectors.getSelectors();
        
        // 3. Prepara o array de facetas
        address[] memory facets = new address[](4);
        facets[0] = adminFacet;
        facets[1] = nftFacet;
        facets[2] = ceremonyFacet;
        facets[3] = votingFacet;
        
        // 4. Implanta o Diamond com todas as facetas
        address diamond = diamondDeployer.deployDiamond(_owner, facets, allSelectors);
        
        emit DeploymentCompleted(diamond, facets);
        return diamond;
    }
    
    /**
     * @dev Implanta apenas a AdminFacet e a adiciona ao Diamond existente
     * @param _diamond Endereço do Diamond
     * @return Endereço da faceta implantada
     */
    function deployAndAddAdminFacet(address _diamond) external returns (address) {
        address facet = facetDeployer.deployAdminFacet();
        bytes4[] memory selectors = AdminFacetSelectors.getSelectors();
        
        diamondDeployer.updateDiamond(
            payable(_diamond),
            facet,
            selectors,
            Diamond.FacetAction.Add
        );
        
        return facet;
    }
    
    /**
     * @dev Implanta apenas a NFTFacet e a adiciona ao Diamond existente
     * @param _diamond Endereço do Diamond
     * @return Endereço da faceta implantada
     */
    function deployAndAddNFTFacet(address _diamond) external returns (address) {
        address facet = facetDeployer.deployNFTFacet();
        bytes4[] memory selectors = NFTFacetSelectors.getSelectors();
        
        diamondDeployer.updateDiamond(
            payable(_diamond),
            facet,
            selectors,
            Diamond.FacetAction.Add
        );
        
        return facet;
    }
    
    /**
     * @dev Implanta apenas a CeremonyFacet e a adiciona ao Diamond existente
     * @param _diamond Endereço do Diamond
     * @return Endereço da faceta implantada
     */
    function deployAndAddCeremonyFacet(address _diamond) external returns (address) {
        address facet = facetDeployer.deployCeremonyFacet();
        bytes4[] memory selectors = CeremonyFacetSelectors.getSelectors();
        
        diamondDeployer.updateDiamond(
            payable(_diamond),
            facet,
            selectors,
            Diamond.FacetAction.Add
        );
        
        return facet;
    }
    
    /**
     * @dev Implanta apenas a VotingFacet e a adiciona ao Diamond existente
     * @param _diamond Endereço do Diamond
     * @return Endereço da faceta implantada
     */
    function deployAndAddVotingFacet(address _diamond) external returns (address) {
        address facet = facetDeployer.deployVotingFacet();
        bytes4[] memory selectors = VotingFacetSelectors.getSelectors();
        
        diamondDeployer.updateDiamond(
            payable(_diamond),
            facet,
            selectors,
            Diamond.FacetAction.Add
        );
        
        return facet;
    }
}
