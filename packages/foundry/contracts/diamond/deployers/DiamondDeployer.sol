// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../ScrumPokerDiamond.sol";
import "../DiamondInit.sol";
import "@solidity-lib/diamond/Diamond.sol";
import "./DeployerUtils.sol";

// Importando a interface IDiamondCutMinimal 
import "./interfaces/IDiamondCutMinimal.sol";

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
    ) external returns (address) {
        require(_facets.length == _selectors.length, "Facets and selectors length mismatch");
        
        // Implanta o Diamond
        ScrumPokerDiamond diamond = new ScrumPokerDiamond(_owner);
        
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
        
        // Implanta o DiamondInit para inicialização
        DiamondInit diamondInit = new DiamondInit();
        
        // Adiciona as facetas ao Diamond usando a interface minimalista
        IDiamondCutMinimal(address(diamond)).diamondCut(
            cuts,
            address(diamondInit),
            abi.encodeWithSelector(DiamondInit.init.selector)
        );
        
        emit DiamondDeployed(address(diamond), _facets);
        return address(diamond);
    }
    
    /**
     * @dev Atualiza uma faceta no Diamond existente
     * @param _diamond Endereço do Diamond
     * @param _newFacet Endereço da nova faceta
     * @param _selectors Seletores para a faceta
     * @param _action Ação a ser executada (Add, Replace, Remove)
     */
    function updateDiamond(
        address _diamond,
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
        
        IDiamondCutMinimal(_diamond).diamondCut(cut, address(0), "");
    }
}
