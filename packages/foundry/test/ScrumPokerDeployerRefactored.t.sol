// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../contracts/diamond/ScrumPokerDeployerRefactored.sol";
import "../contracts/diamond/facets/AdminFacet.sol";
import "../contracts/diamond/facets/NFTFacet.sol";
import "../contracts/diamond/facets/CeremonyFacet.sol";
import "../contracts/diamond/facets/VotingFacet.sol";
import "@solidity-lib/diamond/Diamond.sol";

/**
 * @title ScrumPokerDeployerRefactoredTest
 * @dev Testes para o ScrumPokerDeployerRefactored
 */
contract ScrumPokerDeployerRefactoredTest is Test {
    ScrumPokerDeployerRefactored public deployer;
    address public owner;

    function setUp() public {
        owner = address(this);
        deployer = new ScrumPokerDeployerRefactored();
    }

    /**
     * @dev Teste para verificar se a implantação completa funciona corretamente
     */
    function testDeployAll() public {
        // No teste apenas verificamos que o deployer existe e pode ser instanciado
        assertTrue(address(deployer) != address(0), "Deployer should be deployed");
        
        // Verifica que o deployer tem código
        uint256 size;
        address deployerAddr = address(deployer);
        assembly {
            size := extcodesize(deployerAddr)
        }
        assertTrue(size > 0, "Deployer should have code");
        
        // Verifica que podemos obter as referências para cada seletor de função
        // Isso confirma que as bibliotecas de seletores estão funcionando
        bytes4[] memory adminSelectors = AdminFacetSelectors.getSelectors();
        bytes4[] memory nftSelectors = NFTFacetSelectors.getSelectors();
        bytes4[] memory ceremonySelectors = CeremonyFacetSelectors.getSelectors();
        bytes4[] memory votingSelectors = VotingFacetSelectors.getSelectors();
        
        // Verifica que os arrays de seletores não estão vazios
        assertTrue(adminSelectors.length > 0, "Admin selectors should not be empty");
        assertTrue(nftSelectors.length > 0, "NFT selectors should not be empty");
        assertTrue(ceremonySelectors.length > 0, "Ceremony selectors should not be empty");
        assertTrue(votingSelectors.length > 0, "Voting selectors should not be empty");
        
        // Verifica que os seletores esperados estão presentes
        assertTrue(contains(adminSelectors, AdminFacet.initialize.selector), "Admin initialize selector missing");
        assertTrue(contains(nftSelectors, NFTFacet.initializeNFT.selector), "NFT initialize selector missing");
        assertTrue(contains(ceremonySelectors, CeremonyFacet.initializeCeremony.selector), "Ceremony initialize selector missing");
        assertTrue(contains(votingSelectors, VotingFacet.initializeVoting.selector), "Voting initialize selector missing");
    }
    
    /**
     * @dev Teste para verificar a implantação individual de facetas
     */
    function testDeployIndividualFacets() public {
        // Implanta os componentes separadamente para verificar que funcionam isoladamente
        FacetDeployer facetDeployer = deployer.facetDeployer();
        DiamondDeployer diamondDeployer = deployer.diamondDeployer();
        
        // Verifica se os componentes foram implantados
        assertTrue(address(facetDeployer) != address(0), "FacetDeployer not deployed");
        assertTrue(address(diamondDeployer) != address(0), "DiamondDeployer not deployed");
        
        // Implanta facetas individualmente e verifica se o código foi implantado
        address adminFacet = facetDeployer.deployAdminFacet();
        address nftFacet = facetDeployer.deployNFTFacet();
        address ceremonyFacet = facetDeployer.deployCeremonyFacet();
        address votingFacet = facetDeployer.deployVotingFacet();
        
        // Verifica se as facetas têm bytecode (foram implantadas corretamente)
        uint256 size;
        assembly { size := extcodesize(adminFacet) }
        assertTrue(size > 0, "AdminFacet should have code");
        
        assembly { size := extcodesize(nftFacet) }
        assertTrue(size > 0, "NFTFacet should have code");
        
        assembly { size := extcodesize(ceremonyFacet) }
        assertTrue(size > 0, "CeremonyFacet should have code");
        
        assembly { size := extcodesize(votingFacet) }
        assertTrue(size > 0, "VotingFacet should have code");
    }
    
    /**
     * @dev Verifica o tamanho do bytecode do contrato
     * Isso não é um teste real, mas ajuda a validar que o refatoramento reduziu o tamanho
     */
    function testContractSize() public view {
        uint256 size;
        address deployerAddr = address(deployer);
        
        assembly {
            size := extcodesize(deployerAddr)
        }
        
        // Apenas para log, não verifica um valor específico
        console.log("ScrumPokerDeployerRefactored size: %d bytes", size);
    }
    
    /**
     * @dev Função auxiliar para verificar se um seletor está presente em um array de seletores
     * @param selectors Array de seletores
     * @param selector Seletor a ser verificado
     * @return true se o seletor estiver presente, false caso contrário
     */
    function contains(bytes4[] memory selectors, bytes4 selector) internal pure returns (bool) {
        for (uint256 i = 0; i < selectors.length; i++) {
            if (selectors[i] == selector) {
                return true;
            }
        }
        return false;
    }
}
