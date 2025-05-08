// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@solidity-lib/diamond/Diamond.sol";
import "./ScrumPokerDiamond.sol";
import "./DiamondInit.sol";
import "./facets/AdminFacet.sol";
import "./facets/NFTFacet.sol";
import "./facets/CeremonyFacet.sol";
import "./facets/VotingFacet.sol";

/**
 * @title ScrumPokerDeployer
 * @dev Script para facilitar a implantação do ScrumPokerDiamond e suas facetas.
 * Este contrato implanta e configura o Diamond com todas as facetas.
 */
contract ScrumPokerDeployer {
    /**
     * @notice Implanta o ScrumPokerDiamond com todas as facetas.
     * @param _owner Endereço do proprietário do contrato.
     * @param _initialExchangeRate Taxa de câmbio inicial (valor em wei equivalente a 1 dólar).
     * @param _vestingPeriod Período de vesting em segundos.
     * @return diamond Endereço do contrato Diamond implantado.
     */
    function deploy(
        address _owner,
        uint256 _initialExchangeRate,
        uint256 _vestingPeriod
    ) external returns (address diamond) {
        // Implanta o contrato Diamond principal
        ScrumPokerDiamond scrumPokerDiamond = new ScrumPokerDiamond(_owner);
        diamond = address(scrumPokerDiamond);
        
        // Implanta as facetas
        AdminFacet adminFacet = new AdminFacet();
        NFTFacet nftFacet = new NFTFacet();
        CeremonyFacet ceremonyFacet = new CeremonyFacet();
        VotingFacet votingFacet = new VotingFacet();
        
        // Implanta o inicializador
        DiamondInit diamondInit = new DiamondInit();
        
        // Prepara os cortes do Diamond (facetas e seus seletores)
        Diamond.Facet[] memory facets = new Diamond.Facet[](4);
        
        // Adiciona a faceta de administração
        facets[0] = Diamond.Facet({
            facetAddress: address(adminFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: _getSelectors("AdminFacet")
        });
        
        // Adiciona a faceta de NFT
        facets[1] = Diamond.Facet({
            facetAddress: address(nftFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: _getSelectors("NFTFacet")
        });
        
        // Adiciona a faceta de cerimônia
        facets[2] = Diamond.Facet({
            facetAddress: address(ceremonyFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: _getSelectors("CeremonyFacet")
        });
        
        // Adiciona a faceta de votação
        facets[3] = Diamond.Facet({
            facetAddress: address(votingFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: _getSelectors("VotingFacet")
        });
        
        // Prepara os dados de inicialização
        bytes memory initData = abi.encodeWithSelector(
            DiamondInit.init.selector,
            _initialExchangeRate,
            _vestingPeriod,
            _owner
        );
        
        // Remover referência inválida a uint2str
        // Executa o corte do Diamond com inicialização
        scrumPokerDiamond.diamondCut(facets, address(diamondInit), initData);
        
        return diamond;
    }
    
    /**
     * @dev Obtém os seletores de função para uma faceta específica.
     * @param facetName Nome da faceta.
     * @return selectors Array de seletores de função.
     */
    function _getSelectors(string memory facetName) internal pure returns (bytes4[] memory) {
        if (keccak256(bytes(facetName)) == keccak256(bytes("AdminFacet"))) {
            bytes4[] memory selectors = new bytes4[](9);
            selectors[0] = AdminFacet.initialize.selector;
            selectors[1] = AdminFacet.updateExchangeRate.selector;
            selectors[2] = AdminFacet.setPriceOracle.selector;
            selectors[3] = AdminFacet.pause.selector;
            selectors[4] = AdminFacet.unpause.selector;
            selectors[5] = AdminFacet.grantRole.selector;
            selectors[6] = AdminFacet.revokeRole.selector;
            selectors[7] = AdminFacet.hasRole.selector;
            selectors[8] = AdminFacet.getExchangeRate.selector;
            return selectors;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("NFTFacet"))) {
            bytes4[] memory selectors = new bytes4[](7);
            selectors[0] = NFTFacet.initializeNFT.selector;
            selectors[1] = NFTFacet.purchaseNFT.selector;
            selectors[2] = NFTFacet.withdrawFunds.selector;
            selectors[3] = NFTFacet.getBadgeData.selector;
            selectors[4] = NFTFacet.getUserToken.selector;
            selectors[5] = NFTFacet.isVested.selector;
            selectors[6] = NFTFacet.updateBadgeForSprint.selector;
            return selectors;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("CeremonyFacet"))) {
            bytes4[] memory selectors = new bytes4[](10);
            selectors[0] = CeremonyFacet.initializeCeremony.selector;
            selectors[1] = CeremonyFacet.startCeremony.selector;
            selectors[2] = CeremonyFacet.requestCeremonyEntry.selector;
            selectors[3] = CeremonyFacet.approveEntry.selector;
            selectors[4] = CeremonyFacet.concludeCeremony.selector;
            selectors[5] = CeremonyFacet.getCeremony.selector;
            selectors[6] = CeremonyFacet.ceremonyExists.selector;
            selectors[7] = CeremonyFacet.hasRequestedEntry.selector;
            selectors[8] = CeremonyFacet.isApproved.selector;
            return selectors;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("VotingFacet"))) {
            bytes4[] memory selectors = new bytes4[](12);
            selectors[0] = VotingFacet.initializeVoting.selector;
            selectors[1] = VotingFacet.vote.selector;
            selectors[2] = VotingFacet.openFunctionalityVote.selector;
            selectors[3] = VotingFacet.voteFunctionality.selector;
            selectors[4] = VotingFacet.closeFunctionalityVote.selector;
            selectors[5] = VotingFacet.updateBadges.selector;
            selectors[6] = VotingFacet.hasVoted.selector;
            selectors[7] = VotingFacet.getVote.selector;
            selectors[8] = VotingFacet.hasFunctionalityVoted.selector;
            selectors[9] = VotingFacet.getFunctionalityVote.selector;
            return selectors;
        } else {
            return new bytes4[](0);
        }
    }
}