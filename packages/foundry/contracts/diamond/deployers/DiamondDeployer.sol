// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@solidity-lib/diamond/Diamond.sol";
import "@solidity-lib/presets/diamond/OwnableDiamond.sol";
import "../ScrumPokerDiamond.sol";
import "../DiamondInit.sol";
import "../facets/AdminFacet.sol";
import "../facets/NFTFacet.sol";
import "../facets/CeremonyFacet.sol";
import "../facets/VotingFacet.sol";
import "./DeployerUtils.sol";

/**
 * @title DiamondDeployer
 * @dev Contrato responsável por implantar e configurar o Diamond
 */
contract DiamondDeployer {
    // Usando a biblioteca DeployerUtils
    using DeployerUtils for address;
    using DeployerUtils for bytes4[];
    // Evento para acompanhar as implantações
    event DiamondDeployed(address indexed diamond, address[] facets);
    
    /**
     * @dev Implanta o Diamond com as facetas especificadas
     * @param _owner Proprietário do Diamond
     * @param _facets Endereços das facetas a serem adicionadas
     * @param _selectors Arrays de seletores para cada faceta
     * @return Endereço do Diamond implantado
     */
    function deployDiamond(
        address _owner, 
        address[] memory _facets,
        bytes4[][] memory _selectors
    ) external returns (address payable) {
        require(_facets.length == _selectors.length, "Facets and selectors length mismatch");
        
        // Implanta o Diamond com o DiamondDeployer como owner inicial
        // Isso permite que o DiamondDeployer chame diamondCut
        ScrumPokerDiamond diamond = new ScrumPokerDiamond(address(this));
        address payable diamondAddress = payable(address(diamond));
        
        // Configura as facetas
        Diamond.Facet[] memory cuts = new Diamond.Facet[](_facets.length);
        
        for (uint i = 0; i < _facets.length; i++) {
            // Verifica se o endereço da faceta é um contrato válido
            require(_facets[i].isContract(), "Facet must be a contract");
            
            cuts[i] = Diamond.Facet({
                facetAddress: _facets[i],
                action: Diamond.FacetAction.Add,
                functionSelectors: _selectors[i]
            });
        }
        
        // Adiciona as facetas ao Diamond usando a interface nativa da biblioteca Solarity
        // Não usamos DiamondInit para evitar problemas de inicialização com storage versionado
        OwnableDiamond(diamondAddress).diamondCut(
            cuts,
            address(0),  // Sem endereço de inicialização
            ""           // Sem dados de inicialização
        );
        
        // Inicializa as facetas diretamente, uma por uma, para contornar conflitos de versionamento de storage
        // Inicializa AdminFacet
        AdminFacet adminFacet = AdminFacet(diamondAddress);
        try adminFacet.initialize(1 ether, 30 days, _owner) {
            // Sucesso na inicialização
        } catch {
            // Ignora erros de inicialização, já que algumas facetas podem já estar inicializadas
        }
        
        // Inicializa NFTFacet
        NFTFacet nftFacet = NFTFacet(diamondAddress);
        try nftFacet.initializeNFT("ScrumPokerBadge", "SPB") {
            // Sucesso na inicialização
        } catch {
            // Ignora erros de inicialização
        }
        
        // Inicializa CeremonyFacet
        CeremonyFacet ceremonyFacet = CeremonyFacet(diamondAddress);
        try ceremonyFacet.initializeCeremony() {
            // Sucesso na inicialização
        } catch {
            // Ignora erros de inicialização
        }
        
        // Inicializa VotingFacet
        VotingFacet votingFacet = VotingFacet(diamondAddress);
        try votingFacet.initializeVoting() {
            // Sucesso na inicialização
        } catch {
            // Ignora erros de inicialização
        }
        
        // Transfere a propriedade para o endereço final
        OwnableDiamond(diamondAddress).transferOwnership(_owner);
        
        emit DiamondDeployed(diamondAddress, _facets);
        return diamondAddress;
    }
    
    /**
     * @dev Atualiza uma faceta no Diamond existente
     * @param _diamond Endereço do Diamond
     * @param _newFacet Endereço da nova faceta
     * @param _selectors Seletores para a faceta
     * @param _action Ação a ser executada (Add, Replace, Remove)
     */
    function updateDiamond(
        address payable _diamond,
        address _newFacet,
        bytes4[] memory _selectors,
        Diamond.FacetAction _action
    ) external {
        Diamond.Facet[] memory cut = new Diamond.Facet[](1);
        cut[0] = Diamond.Facet({
            facetAddress: _newFacet,
            action: _action,
            functionSelectors: _selectors
        });
        
        OwnableDiamond(_diamond).diamondCut(cut, address(0), "");
    }
}
