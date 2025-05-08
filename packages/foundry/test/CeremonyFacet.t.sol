// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {ScrumPokerDiamond} from "../contracts/diamond/ScrumPokerDiamond.sol";
import {CeremonyFacet} from "../contracts/diamond/facets/CeremonyFacet.sol";
import {ScrumPokerStorage} from "../contracts/diamond/ScrumPokerStorage.sol";
import {AdminFacet} from "../contracts/diamond/facets/AdminFacet.sol";

// Interface para testar o diamondCut (conforme padrao EIP-2535)
interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }
    
    function diamondCut(FacetCut[] calldata cuts, address init, bytes calldata _calldata) external;
}

contract CeremonyFacetTest is Test {
    ScrumPokerDiamond scrumPokerDiamond;
    CeremonyFacet ceremonyFacet;
    AdminFacet adminFacet;
    
    address owner = address(0xABCD);
    address user1 = address(0x1234);
    address user2 = address(0x5678);
    
    // Função auxiliar para realizar o corte do diamante
    function _diamondCut(
        IDiamondCut.FacetCut[] memory cuts,
        address _init,
        bytes memory _calldata
    ) internal {
        // Obtém a interface do contrato de corte
        IDiamondCut diamondCut = IDiamondCut(address(scrumPokerDiamond));
        // Aplica o corte
        diamondCut.diamondCut(cuts, _init, _calldata);
    }
    
    // Função auxiliar para adicionar uma faceta ao diamante
    function _addFacet(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: _functionSelectors
        });
        _diamondCut(cut, address(0), "");
    }

    function setUp() public {
        // Cria as facetas para teste
        ceremonyFacet = new CeremonyFacet();
        adminFacet = new AdminFacet();
        
        // Cria o contrato Diamond principal com o owner
        scrumPokerDiamond = new ScrumPokerDiamond(owner);
        
        // Seleciona as funções da CeremonyFacet
        bytes4[] memory ceremonySelectors = new bytes4[](8);
        ceremonySelectors[0] = ceremonyFacet.initializeCeremony.selector;
        ceremonySelectors[1] = ceremonyFacet.startCeremony.selector;
        ceremonySelectors[2] = ceremonyFacet.requestCeremonyEntry.selector;
        ceremonySelectors[3] = ceremonyFacet.approveEntry.selector;
        ceremonySelectors[4] = ceremonyFacet.concludeCeremony.selector;
        ceremonySelectors[5] = ceremonyFacet.getCeremony.selector;
        ceremonySelectors[6] = ceremonyFacet.ceremonyExists.selector;
        ceremonySelectors[7] = ceremonyFacet.isApproved.selector;
        
        // Seleciona as funções do AdminFacet
        bytes4[] memory adminSelectors = new bytes4[](2);
        adminSelectors[0] = adminFacet.grantRole.selector;
        adminSelectors[1] = adminFacet.revokeRole.selector;
        
        // Prepara os cortes para adicionar todas as facetas
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](2);
        
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(ceremonyFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ceremonySelectors
        });
        
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(adminFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: adminSelectors
        });
        
        // Adiciona os facets e inicializa como owner para evitar problemas de autorização
        vm.startPrank(owner);
        _diamondCut(cuts, address(0), "");
        
        // Primeiro, precisamos criar a role ADMIN para o owner usando o internal storage diretamente
        bytes32 adminRole = keccak256("ADMIN_ROLE");
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        ds.roles[adminRole][owner] = true;
        
        // Agora podemos inicializar a CeremonyFacet com owner tendo a role ADMIN
        CeremonyFacet(address(scrumPokerDiamond)).initializeCeremony();
        vm.stopPrank();
        
        // Configura user1 e user2 como tendo NFTs (implementação futura)
    }

    /**
     * @dev Teste para verificar que a reinicialização deve falhar com InvalidInitialization
     */
    function testStorageVersionInitialization() public {
        vm.startPrank(owner);
        // A inicialização já ocorreu no setUp, então a segunda tentativa deve falhar
        vm.expectRevert(bytes4(keccak256("InvalidInitialization()"))); // Erro personalizado do Initializable
        CeremonyFacet(address(scrumPokerDiamond)).initializeCeremony();
        vm.stopPrank();
    }

    /**
     * @dev Teste para criar uma cerimônia usando o novo sistema versionado
     */
    function testStartCeremonyWithVersionedStorage() public {
        vm.startPrank(owner);
        // Inicia uma nova cerimônia
        string memory code = CeremonyFacet(address(scrumPokerDiamond)).startCeremony(1);
        
        // Verifica se a cerimônia existe
        bool exists = CeremonyFacet(address(scrumPokerDiamond)).ceremonyExists(code);
        assertTrue(exists, "A cerimonia deveria existir");
        
        // Obtém os detalhes da cerimônia
        (string memory returnedCode, 
         uint256 sprintNumber, 
         uint256 startTime, 
         uint256 endTime, 
         address scrumMaster, 
         bool active, 
         address[] memory participants) = CeremonyFacet(address(scrumPokerDiamond)).getCeremony(code);
         
        // Verifica se os dados estão corretos
        assertEq(returnedCode, code, "Os codigos devem ser iguais");
        assertEq(sprintNumber, 1, "O numero do sprint deve ser 1");
        assertEq(scrumMaster, owner, "O scrumMaster deve ser o owner");
        assertTrue(active, "A cerimonia deve estar ativa");
        assertEq(participants.length, 0, "Inicialmente nao deve haver participantes");
        vm.stopPrank();
    }
    
    /**
     * @dev Teste para solicitar e aprovar entrada em uma cerimônia
     */
    function testRequestAndApproveEntryWithVersionedStorage() public {
        vm.startPrank(owner);
        // Inicia uma nova cerimônia
        string memory code = CeremonyFacet(address(scrumPokerDiamond)).startCeremony(1);
        vm.stopPrank();
        
        // Simula que user1 tem um NFT
        vm.startPrank(user1);
        // Mock para vestingStart e userToken
        vm.mockCall(
            address(scrumPokerDiamond),
            abi.encodeWithSignature("userToken(address)", user1),
            abi.encode(1) // user1 tem tokenId 1
        );
        
        // Solicita entrada na cerimônia
        CeremonyFacet(address(scrumPokerDiamond)).requestCeremonyEntry(code);
        vm.stopPrank();
        
        // O owner aprova a entrada do user1
        vm.startPrank(owner);
        CeremonyFacet(address(scrumPokerDiamond)).approveEntry(code, user1);
        
        // Verifica se o user1 foi aprovado
        bool isApproved = CeremonyFacet(address(scrumPokerDiamond)).isApproved(code, user1);
        assertTrue(isApproved, "O user1 deveria estar aprovado");
        vm.stopPrank();
    }
    
    /**
     * @dev Teste para concluir uma cerimônia
     */
    function testConcludeCeremonyWithVersionedStorage() public {
        vm.startPrank(owner);
        // Inicia uma nova cerimônia
        string memory code = CeremonyFacet(address(scrumPokerDiamond)).startCeremony(1);
        
        // Conclui a cerimônia
        CeremonyFacet(address(scrumPokerDiamond)).concludeCeremony(code);
        
        // Obtém os detalhes da cerimônia
        (,,,, address scrumMaster, bool active,) = CeremonyFacet(address(scrumPokerDiamond)).getCeremony(code);
        
        // Verifica se foi concluída
        assertEq(scrumMaster, owner, "O scrumMaster deve ser o owner");
        assertFalse(active, "A cerimonia nao deve estar ativa apos conclusao");
        vm.stopPrank();
    }

    function testCeremonyExistsReturnsFalseInitially() public view {
        string memory code = "SPRINT1";
        assertFalse(ceremonyFacet.ceremonyExists(code));
    }

    function testHasRequestedEntryReturnsFalseInitially() public view {
        string memory code = "SPRINT1";
        assertFalse(ceremonyFacet.hasRequestedEntry(code, user1));
    }
}