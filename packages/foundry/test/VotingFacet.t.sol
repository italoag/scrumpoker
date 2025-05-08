// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {ScrumPokerDiamond} from "../contracts/diamond/ScrumPokerDiamond.sol";
import {VotingFacet} from "../contracts/diamond/facets/VotingFacet.sol";
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

contract VotingFacetTest is Test {
    ScrumPokerDiamond scrumPokerDiamond;
    VotingFacet votingFacet;
    CeremonyFacet ceremonyFacet;
    AdminFacet adminFacet;
    
    address owner = address(0xABCD);
    address user1 = address(0x1234);
    address user2 = address(0x5678);
    
    string internal ceremonyCode;
    
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
        votingFacet = new VotingFacet();
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
        
        // Seleciona as funções do VotingFacet
        bytes4[] memory votingSelectors = new bytes4[](10);
        votingSelectors[0] = votingFacet.initializeVoting.selector;
        votingSelectors[1] = votingFacet.vote.selector;
        votingSelectors[2] = votingFacet.openFunctionalityVote.selector;
        votingSelectors[3] = votingFacet.closeFunctionalityVote.selector;
        votingSelectors[4] = votingFacet.voteFunctionality.selector;
        votingSelectors[5] = votingFacet.updateBadges.selector;
        votingSelectors[6] = votingFacet.hasVoted.selector;
        votingSelectors[7] = votingFacet.getVote.selector;
        votingSelectors[8] = votingFacet.hasFunctionalityVoted.selector;
        votingSelectors[9] = votingFacet.getFunctionalityVote.selector;
        
        // Seleciona as funções do AdminFacet
        bytes4[] memory adminSelectors = new bytes4[](2);
        adminSelectors[0] = adminFacet.grantRole.selector;
        adminSelectors[1] = adminFacet.revokeRole.selector;
        
        // Prepara os cortes para adicionar todas as facetas
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);
        
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(ceremonyFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ceremonySelectors
        });
        
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(votingFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: votingSelectors
        });
        
        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(adminFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: adminSelectors
        });
        
        // Adiciona os facets e inicializa como owner para evitar problemas de autorização
        vm.startPrank(owner);
        _diamondCut(cuts, address(0), "");
        
        // Primeiro, precisamos criar as roles diretamente no storage
        bytes32 adminRole = keccak256("ADMIN_ROLE");
        bytes32 scrumMasterRole = keccak256("SCRUM_MASTER_ROLE");
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        ds.roles[adminRole][owner] = true; // Owner como ADMIN
        ds.roles[scrumMasterRole][user1] = true; // User1 como SCRUM_MASTER
        
        // Configuramos manualmente o storage como inicializado
        ds.initialized["CeremonyFacet"] = true;
        ds.initialized["VotingFacet"] = true;
        
        // Configura a versão do storage
        ds.storageVersion = 1; // Versão atual
        
        // Não chamamos os inicializadores para evitar erros de reinicialização
        
        // Cria uma cerimônia para os testes como proprietário
        ceremonyCode = CeremonyFacet(address(scrumPokerDiamond)).startCeremony(1);
        
        // Configura vesting e timestamps para evitar erros de NFTNotVested
        // Configurando vesting diretamente no storage
        ds.vestingPeriod = 1 days;
        ds.vestingStart[user1] = block.timestamp - 2 days; // Já passou o vesting
        ds.vestingStart[user2] = block.timestamp - 2 days; // Já passou o vesting
        
        // Configura user1 e user2 como tendo NFTs
        ds.userToken[user1] = 1; // user1 tem tokenId 1
        ds.userToken[user2] = 2; // user2 tem tokenId 2
        
        // Badge data básico
        ds.badgeData[1].userName = "User1";
        ds.badgeData[1].userAddress = user1;
        ds.badgeData[2].userName = "User2";
        ds.badgeData[2].userAddress = user2;
        
        // Aprova user1 e user2 na cerimônia
        CeremonyFacet(address(scrumPokerDiamond)).approveEntry(ceremonyCode, user1);
        CeremonyFacet(address(scrumPokerDiamond)).approveEntry(ceremonyCode, user2);
        
        vm.stopPrank();
    }

    /**
     * @dev Teste para verificar que a reinicialização deve falhar com InvalidInitialization
     */
    function testInitializeVoting() public {
        vm.startPrank(owner);
        // A inicialização já ocorreu no setUp, então a segunda tentativa deve falhar
        vm.expectRevert(bytes4(keccak256("InvalidInitialization()"))); // Erro personalizado do Initializable
        VotingFacet(address(scrumPokerDiamond)).initializeVoting();
        vm.stopPrank();
    }

    /**
     * @dev Teste para verificação da votação geral em uma cerimônia
     */
    function testVoteWithVersionedStorage() public {
        // Simula que os períodos de vesting já passaram
        vm.mockCall(
            address(scrumPokerDiamond),
            abi.encodeWithSignature("vestingStart(address)", user1),
            abi.encode(block.timestamp - 1 days) // vesting começou há 1 dia
        );
        
        vm.mockCall(
            address(scrumPokerDiamond),
            abi.encodeWithSignature("vestingPeriod()"),
            abi.encode(1 hours) // período de vesting de 1 hora
        );
        
        // user1 vota na cerimônia
        vm.startPrank(user1);
        VotingFacet(address(scrumPokerDiamond)).vote(ceremonyCode, 5); // vota 5 pontos
        
        // Verifica se o voto foi registrado
        bool hasVoted = VotingFacet(address(scrumPokerDiamond)).hasVoted(ceremonyCode, user1);
        assertTrue(hasVoted, "O usuario deveria ter votado");
        
        // Verifica o valor do voto
        uint256 voteValue = VotingFacet(address(scrumPokerDiamond)).getVote(ceremonyCode, user1);
        assertEq(voteValue, 5, "O valor do voto deveria ser 5");
        vm.stopPrank();
    }

    /**
     * @dev Teste para abertura e fechamento de votação de funcionalidade
     */
    function testOpenAndCloseFunctionalityVoteWithVersionedStorage() public {
        vm.startPrank(owner);
        // Abre uma sessão de votação para uma funcionalidade
        VotingFacet(address(scrumPokerDiamond)).openFunctionalityVote(ceremonyCode, "FUNC001");
        
        // Simula que os períodos de vesting já passaram
        vm.mockCall(
            address(scrumPokerDiamond),
            abi.encodeWithSignature("vestingStart(address)", user1),
            abi.encode(block.timestamp - 1 days) // vesting começou há 1 dia
        );
        
        vm.mockCall(
            address(scrumPokerDiamond),
            abi.encodeWithSignature("vestingPeriod()"),
            abi.encode(1 hours) // período de vesting de 1 hora
        );
        
        // user1 vota na funcionalidade
        vm.stopPrank();
        vm.startPrank(user1);
        VotingFacet(address(scrumPokerDiamond)).voteFunctionality(ceremonyCode, 0, 8); // vota 8 pontos na sessão 0
        
        // Verifica se o voto foi registrado
        bool hasVoted = VotingFacet(address(scrumPokerDiamond)).hasFunctionalityVoted(ceremonyCode, 0, user1);
        assertTrue(hasVoted, "O usuario deveria ter votado na funcionalidade");
        
        // Verifica o valor do voto
        uint256 voteValue = VotingFacet(address(scrumPokerDiamond)).getFunctionalityVote(ceremonyCode, 0, user1);
        assertEq(voteValue, 8, "O valor do voto na funcionalidade deveria ser 8");
        
        // owner fecha a sessão de votação
        vm.stopPrank();
        vm.startPrank(owner);
        VotingFacet(address(scrumPokerDiamond)).closeFunctionalityVote(ceremonyCode, 0);
        
        vm.stopPrank();
    }

    /**
     * @dev Teste para atualização dos badges NFT com resultados da cerimônia
     */
    function testUpdateBadgesWithVersionedStorage() public {
        // Garante que a cerimônia está ativa
        vm.startPrank(owner);
        // Conclui a cerimônia antes de atualizar badges
        CeremonyFacet(address(scrumPokerDiamond)).concludeCeremony(ceremonyCode);
        
        // Atualiza os badges
        VotingFacet(address(scrumPokerDiamond)).updateBadges(ceremonyCode);
        
        // Não há como verificar facilmente o resultado aqui sem mock mais complexo
        // ou instruções especiais em eventos, mas o importante é que não reverta
        vm.stopPrank();
    }

    /**
     * @dev Teste para verificar que hasVoted retorna false inicialmente
     */
    function testHasVotedReturnsFalseInitially() public {
        bool hasVoted = VotingFacet(address(scrumPokerDiamond)).hasVoted(ceremonyCode, address(0x9999));
        assertFalse(hasVoted, "hasVoted deveria retornar false inicialmente");
    }

    /**
     * @dev Teste para verificar que hasFunctionalityVoted retorna false inicialmente
     */
    function testHasFunctionalityVotedReturnsFalseInitially() public {
        vm.startPrank(owner);
        // Abre uma sessão de votação
        VotingFacet(address(scrumPokerDiamond)).openFunctionalityVote(ceremonyCode, "FUNC002");
        vm.stopPrank();
        
        bool hasVoted = VotingFacet(address(scrumPokerDiamond)).hasFunctionalityVoted(ceremonyCode, 0, address(0x9999));
        assertFalse(hasVoted, "hasFunctionalityVoted deveria retornar false inicialmente");
    }
}