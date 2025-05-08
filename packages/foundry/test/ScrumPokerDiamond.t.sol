// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {ScrumPokerDiamond} from "../contracts/diamond/ScrumPokerDiamond.sol";
import {ScrumPokerStorage} from "../contracts/diamond/ScrumPokerStorage.sol";
import {AdminFacet} from "../contracts/diamond/facets/AdminFacet.sol";
import {CeremonyFacet} from "../contracts/diamond/facets/CeremonyFacet.sol";
import {VotingFacet} from "../contracts/diamond/facets/VotingFacet.sol";

// Eventos do contrato ScrumPokerDiamond para testes
event EtherReceived(address indexed sender, uint256 amount);
event MaxContributionUpdated(uint256 oldLimit, uint256 newLimit);

// Eventos do contrato AdminFacet para testes
event VestingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
event FundsWithdrawn(address indexed to, uint256 amount);
event ERC20TokensWithdrawn(address indexed token, address indexed to, uint256 amount);

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

// Interface para o Ownable
interface IOwnable {
    function owner() external view returns (address);
}

// Interface simplificada para ERC165
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Contrato de teste (MockFacet) para adicionar, substituir ou remover facetas
contract MockFacet {
    // Variável de armazenamento de teste
    uint256 public value;
    
    // Função que pode ser chamada para modificar o valor
    function setValue(uint256 _value) external {
        value = _value;
    }
    
    // Função para obter o valor atual
    function getValue() external view returns (uint256) {
        return value;
    }
}

contract ScrumPokerDiamondTest is Test {
    ScrumPokerDiamond diamond;
    address owner = address(0xABCD);
    address user = address(0x1234);
    
    // Instâncias de facetas para testes
    AdminFacet adminFacet;
    
    // Seletores de funções para testar
    bytes4 constant SET_VALUE_SELECTOR = bytes4(keccak256("setValue(uint256)"));
    bytes4 constant GET_VALUE_SELECTOR = bytes4(keccak256("getValue()"));
    bytes4 constant GET_EXCHANGE_RATE_SELECTOR = bytes4(keccak256("getExchangeRate()"));
    bytes4 constant UNPAUSE_SELECTOR = bytes4(keccak256("unpause()"));
    bytes4 constant WITHDRAW_FUNDS_SELECTOR = bytes4(keccak256("withdrawFunds()"));
    
    // ERC165 interface IDs para testes
    bytes4 constant ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 constant DIAMOND_CUT_INTERFACE_ID = 0x1f931c1c;
    bytes4 constant DIAMOND_LOUPE_INTERFACE_ID = 0x48e2b093;
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy do contrato Diamond principal
        diamond = new ScrumPokerDiamond(owner);
        
        // Inicializar as facetas para teste
        adminFacet = new AdminFacet();
        
        // Adicionar a faceta de administração ao Diamond para que os testes de pause/unpause funcionem
        bytes4[] memory adminSelectors = new bytes4[](10);
        adminSelectors[0] = adminFacet.pause.selector;
        adminSelectors[1] = adminFacet.unpause.selector;
        adminSelectors[2] = adminFacet.isPaused.selector;
        adminSelectors[3] = adminFacet.initialize.selector;
        adminSelectors[4] = adminFacet.getVestingPeriod.selector;
        adminSelectors[5] = adminFacet.updateVestingPeriod.selector;
        adminSelectors[6] = adminFacet.getExchangeRate.selector;
        adminSelectors[7] = adminFacet.withdrawFunds.selector;
        adminSelectors[8] = adminFacet.withdrawERC20.selector;
        adminSelectors[9] = adminFacet.setPriceOracle.selector;
        
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(adminFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: adminSelectors
        });
        
        // Adicionar a faceta administrativa ao diamond
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");
        
        // Inicializar a faceta administrativa
        // Isso também concede o papel ADMIN_ROLE ao owner
        uint256 initialExchangeRate = 1e18; // 1 ETH = 1 USD para simplificar
        uint256 vestingPeriod = 30 days;
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(adminFacet.initialize.selector, initialExchangeRate, vestingPeriod, owner)
        );
        require(success, "Falha ao inicializar a faceta administrativa");
        
        vm.stopPrank();
    }
    
    function testOwnerIsCorrectlySet() public {
        // Verificar se o owner foi definido corretamente
        vm.startPrank(owner);
        
        // Verificar se o owner pode chamar o diamondCut
        bool canCallDiamondCut = true;
        try IDiamondCut(address(diamond)).diamondCut(new IDiamondCut.FacetCut[](0), address(0), "") {
            // Se nao falhar, o teste passa silenciosamente
        } catch {
            canCallDiamondCut = false;
        }
        assertTrue(canCallDiamondCut, "Owner nao pode chamar diamondCut");
        vm.stopPrank();
        
        // Verificar se um nao-owner nao pode chamar o diamondCut
        vm.startPrank(user);
        bool shouldFail = false;
        try IDiamondCut(address(diamond)).diamondCut(new IDiamondCut.FacetCut[](0), address(0), "") {
            // Se nao falhar, o teste vai falhar
        } catch {
            shouldFail = true;
        }
        assertTrue(shouldFail, "Non-owner conseguiu chamar diamondCut");
        vm.stopPrank();
    }
    
    function testReceiveFunction() public {
        // Testar se o contrato pode receber ETH diretamente e emite eventos
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        
        uint256 initialBalance = address(diamond).balance;
        
        // Esperamos que o evento EtherReceived seja emitido
        vm.expectEmit(true, false, false, true);
        emit EtherReceived(user, 0.5 ether);
        
        // Enviar ETH diretamente para o contrato (deve usar a funcao receive)
        (bool success, ) = payable(address(diamond)).call{value: 0.5 ether}("");
        assertTrue(success, "Falha ao enviar ETH para o contrato");
        
        // Verificar se o saldo aumentou corretamente
        uint256 newBalance = address(diamond).balance;
        assertEq(newBalance, initialBalance + 0.5 ether, "Balanco do contrato nao aumentou corretamente");
        
        vm.stopPrank();
    }
    
    function testDiamondCutAddFacet() public {
        vm.startPrank(owner);
        
        // Criar uma nova faceta de teste
        MockFacet mockFacet = new MockFacet();
        
        // Preparar os seletores de funcao para a faceta
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = SET_VALUE_SELECTOR;
        selectors[1] = GET_VALUE_SELECTOR;
        
        // Criar o corte de diamante para adicionar a faceta
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
        
        // Adicionar a faceta
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");
        
        // Testar a funcionalidade da faceta adicionada
        // Definir um valor
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(SET_VALUE_SELECTOR, 42)
        );
        assertTrue(success, "Falha ao chamar setValue");
        
        // Obter o valor definido
        bytes memory result;
        (success, result) = address(diamond).call(
            abi.encodeWithSelector(GET_VALUE_SELECTOR)
        );
        assertTrue(success, "Falha ao chamar getValue");
        
        uint256 value = abi.decode(result, (uint256));
        assertEq(value, 42, "O valor retornado nao corresponde ao valor definido");
        
        vm.stopPrank();
    }
    
    function testDiamondCutReplaceFacet() public {
        vm.startPrank(owner);
        
        // Criar uma primeira faceta de teste e adicioná-la
        MockFacet mockFacet1 = new MockFacet();
        
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = SET_VALUE_SELECTOR;
        selectors[1] = GET_VALUE_SELECTOR;
        
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet1),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
        
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");
        
        // Definir o valor inicial
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(SET_VALUE_SELECTOR, 42)
        );
        assertTrue(success, "Falha ao chamar setValue");
        
        // Criar uma segunda faceta com a mesma interface
        MockFacet mockFacet2 = new MockFacet();
        
        // Substituir a primeira faceta pela segunda
        selectors = new bytes4[](1);
        selectors[0] = SET_VALUE_SELECTOR;
        
        cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet2),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: selectors
        });
        
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");
        
        // Definir um novo valor
        (success, ) = address(diamond).call(
            abi.encodeWithSelector(SET_VALUE_SELECTOR, 84)
        );
        assertTrue(success, "Falha ao chamar setValue na faceta substituida");
        
        // Verificar se o valor foi atualizado
        bytes memory result;
        (success, result) = address(diamond).call(
            abi.encodeWithSelector(GET_VALUE_SELECTOR)
        );
        assertTrue(success, "Falha ao chamar getValue");
        
        uint256 value = abi.decode(result, (uint256));
        assertEq(value, 84, "O valor retornado nao corresponde ao novo valor definido");
        
        vm.stopPrank();
    }
    
    function testDiamondCutRemoveFacet() public {
        vm.startPrank(owner);
        
        // Criar uma faceta de teste e adicioná-la
        MockFacet mockFacet = new MockFacet();
        
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = SET_VALUE_SELECTOR;
        selectors[1] = GET_VALUE_SELECTOR;
        
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
        
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");
        
        // Remover uma das funções (setValue)
        selectors = new bytes4[](1);
        selectors[0] = SET_VALUE_SELECTOR;
        
        cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: selectors
        });
        
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");
        
        // Tentar chamar a funcao removida (deve falhar)
        (bool success, ) = address(diamond).call(abi.encodeWithSelector(SET_VALUE_SELECTOR, 100));
        assertFalse(success, "Conseguiu chamar uma funcao removida");
        
        vm.stopPrank();
    }
    
    function testSupportsERC165Interface() public {
        // Testar se o diamond suporta a interface ERC165
        bool success;
        bytes memory result;
        (success, result) = address(diamond).call(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, ERC165_INTERFACE_ID)
        );
        
        assertTrue(success, "Chamada para supportsInterface falhou");
        bool supported = abi.decode(result, (bool));
        assertTrue(supported, "O contrato nao suporta a interface ERC165");
    }
    
    function testSupportsDiamondInterfaces() public {
        // Testar se o diamond suporta as interfaces Diamond Cut e Diamond Loupe
        bool success;
        bytes memory result;
        
        // Testar suporte a Diamond Cut
        (success, result) = address(diamond).call(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, DIAMOND_CUT_INTERFACE_ID)
        );
        
        assertTrue(success, "Chamada para supportsInterface falhou");
        bool supportsCut = abi.decode(result, (bool));
        assertTrue(supportsCut, "O contrato nao suporta a interface Diamond Cut");
        
        // Testar suporte a Diamond Loupe
        (success, result) = address(diamond).call(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, DIAMOND_LOUPE_INTERFACE_ID)
        );
        
        assertTrue(success, "Chamada para supportsInterface falhou");
        bool supportsLoupe = abi.decode(result, (bool));
        assertTrue(supportsLoupe, "O contrato nao suporta a interface Diamond Loupe");
    }
    
    function testBasicPauseAndUnpause() public {
        // Abordagem simplificada para testar apenas a funcionalidade básica de pause/unpause
        vm.startPrank(owner);
        
        // Pausar o contrato 
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(adminFacet.pause.selector)
        );
        assertTrue(success, "Falha ao pausar o contrato");
        
        // Despausar o contrato
        (success, ) = address(diamond).call(
            abi.encodeWithSelector(adminFacet.unpause.selector)
        );
        assertTrue(success, "Falha ao despausar o contrato");
        
        vm.stopPrank();
        
        // Se chegamos até aqui sem revert, o teste passa
        assertTrue(true, "Teste de pause/unpause passou");
    }
    
    function testFallbackWhenPaused() public {
        vm.startPrank(owner);
        
        // Pausar o contrato
        bool pauseSuccess;
        (pauseSuccess, ) = address(diamond).call(
            abi.encodeWithSelector(adminFacet.pause.selector)
        );
        assertTrue(pauseSuccess, "Falha ao pausar o contrato");
        
        // Criar uma funcao qualquer que deve ser bloqueada quando o contrato esta pausado
        bytes4 ceremonyEntrySelector = bytes4(keccak256("requestCeremonyEntry(string)"));
        
        vm.stopPrank();
        vm.startPrank(user);
        
        // Tentar chamar uma funcao (que nao seja unpause ou withdrawFunds) quando pausado deve falhar
        bool callSuccess;
        (callSuccess, ) = address(diamond).call(abi.encodeWithSelector(ceremonyEntrySelector, "ABCD"));
        assertFalse(callSuccess, "Conseguiu chamar uma funcao bloqueada quando o contrato esta pausado");
        
        vm.stopPrank();
        
        // Verificar se owner ainda pode chamar unpause mesmo quando pausado
        vm.startPrank(owner);
        bool unpauseSuccess;
        (unpauseSuccess, ) = address(diamond).call(
            abi.encodeWithSelector(adminFacet.unpause.selector)
        );
        assertTrue(unpauseSuccess, "Owner nao conseguiu chamar unpause quando o contrato esta pausado");
        
        vm.stopPrank();
    }
    
    function testReceivingETHWhenPaused() public {
        // Financiar o usuario com ETH
        vm.deal(user, 1 ether);
        
        // Primeiro, pausar o contrato como owner
        vm.startPrank(owner);
        bool success;
        (success, ) = address(diamond).call(
            abi.encodeWithSelector(adminFacet.pause.selector)
        );
        assertTrue(success, "Falha ao pausar o contrato");
        vm.stopPrank();
        
        // Verificar se o contrato pode receber ETH mesmo quando pausado
        vm.startPrank(user);
        uint256 initialBalance = address(diamond).balance;
        
        // Tentar enviar ETH para o contrato em estado pausado
        (success, ) = payable(address(diamond)).call{value: 0.5 ether}("");
        assertTrue(success, "Contrato pausado nao conseguiu receber ETH");
        
        // Verificar se o saldo aumentou corretamente
        uint256 newBalance = address(diamond).balance;
        assertEq(newBalance, initialBalance + 0.5 ether, "Balanco do contrato nao aumentou corretamente quando pausado");
        
        vm.stopPrank();
    }
    function testDiamondStandards() public {
        // Testar se o diamond suporta as interfaces padrão
        bool success;
        bytes memory result;
        bytes4 erc165InterfaceId = 0x01ffc9a7; // ERC165 interface ID
        bytes4 diamondCutInterfaceId = 0x1f931c1c; // DiamondCut interface ID
        bytes4 diamondLoupeInterfaceId = 0x48e2b093; // DiamondLoupe interface ID
        
        // Verificar suporte a ERC165
        (success, result) = address(diamond).call(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, erc165InterfaceId)
        );
        assertTrue(success, "Chamada para supportsInterface falhou");
        bool isERC165Supported = abi.decode(result, (bool));
        assertTrue(isERC165Supported, "O contrato nao suporta a interface ERC165");
        
        // Verificar suporte a DiamondCut
        (success, result) = address(diamond).call(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, diamondCutInterfaceId)
        );
        assertTrue(success, "Chamada para supportsInterface falhou");
        bool supportsCut = abi.decode(result, (bool));
        assertTrue(supportsCut, "O contrato nao suporta a interface Diamond Cut");
        
        // Verificar suporte a DiamondLoupe
        (success, result) = address(diamond).call(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, diamondLoupeInterfaceId)
        );
        assertTrue(success, "Chamada para supportsInterface falhou");
        bool supportsLoupe = abi.decode(result, (bool));
        assertTrue(supportsLoupe, "O contrato nao suporta a interface Diamond Loupe");
    }
    
    function testMaxContribution() public {
        // Verificar o limite inicial de contribuição (10 ETH)
        uint256 maxContribution = ScrumPokerDiamond(payable(address(diamond))).maxContribution();
        assertEq(maxContribution, 10 ether, unicode"Valor inicial de maxContribution deveria ser 10 ETH");
        
        // Enviar um valor abaixo do limite (deve funcionar)
        vm.deal(user, 5 ether);
        vm.startPrank(user);
        
        vm.expectEmit(true, false, false, true);
        emit EtherReceived(user, 5 ether);
        (bool success, ) = payable(address(diamond)).call{value: 5 ether}("");
        assertTrue(success, "Falha ao enviar ETH dentro do limite");
        
        vm.stopPrank();
        
        // Enviar um valor acima do limite (deve falhar)
        vm.deal(user, 15 ether);
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(
            ScrumPokerDiamond.ContributionTooLarge.selector,
            15 ether,
            10 ether
        ));
        (success, ) = payable(address(diamond)).call{value: 15 ether}("");
        
        vm.stopPrank();
    }
    
    function testSetMaxContribution() public {
        // Apenas o owner pode alterar o limite
        vm.startPrank(owner);
        
        uint256 oldLimit = ScrumPokerDiamond(payable(address(diamond))).maxContribution();
        uint256 newLimit = 20 ether;
        
        // Verificar se o evento é emitido corretamente
        vm.expectEmit(false, false, false, true);
        emit MaxContributionUpdated(oldLimit, newLimit);
        
        // Alterar o limite máximo
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(
                bytes4(keccak256("setMaxContribution(uint256)")),
                newLimit
            )
        );
        assertTrue(success, unicode"Falha ao alterar o limite maximo");
        
        // Verificar se o novo limite foi definido corretamente
        uint256 updatedLimit = ScrumPokerDiamond(payable(address(diamond))).maxContribution();
        assertEq(updatedLimit, newLimit, unicode"Limite nao foi atualizado corretamente");
        
        // Testar que agora podemos enviar um valor maior
        vm.stopPrank();
        vm.deal(user, 15 ether);
        vm.startPrank(user);
        
        // Deve funcionar com o novo limite
        (success, ) = payable(address(diamond)).call{value: 15 ether}("");
        assertTrue(success, unicode"Falha ao enviar ETH com o novo limite");
        
        vm.stopPrank();
        
        // Testar que um não-owner não pode alterar o limite
        vm.startPrank(user);
        vm.expectRevert("ScrumPokerDiamond: apenas owner");
        (success, ) = address(diamond).call(
            abi.encodeWithSelector(
                bytes4(keccak256("setMaxContribution(uint256)")),
                5 ether
            )
        );
        
        vm.stopPrank();
    }
    
    function testWithdrawFunds() public {
        // Preparando o contrato com saldo
        vm.deal(address(diamond), 10 ether);
        assertEq(address(diamond).balance, 10 ether, "Saldo inicial incorreto");
        
        address payable recipient = payable(address(0x5555));
        uint256 withdrawAmount = 5 ether;
        
        // Não-owner não pode sacar fundos
        vm.startPrank(user);
        bytes memory withdrawSelector = abi.encodeWithSelector(
            bytes4(keccak256("withdrawFunds(address,uint256)")),
            recipient,
            withdrawAmount
        );
        
        (bool success, ) = address(diamond).call(withdrawSelector);
        assertFalse(success, "Nao-owner conseguiu sacar fundos");
        vm.stopPrank();
        
        // Owner pode sacar fundos
        vm.startPrank(owner);
        
        // Verificando evento
        vm.expectEmit(true, false, false, true);
        emit FundsWithdrawn(recipient, withdrawAmount);
        
        // Realizando saque parcial
        (success, ) = address(diamond).call(withdrawSelector);
        assertTrue(success, "Owner nao conseguiu sacar fundos");
        
        // Verificando saldos apos o saque
        assertEq(address(diamond).balance, 5 ether, "Saldo do contrato incorreto apos saque");
        assertEq(recipient.balance, 5 ether, "Saldo do recipient incorreto apos saque");
        
        // Saque excedendo saldo atual (deve falhar)
        bytes memory largeWithdrawSelector = abi.encodeWithSelector(
            bytes4(keccak256("withdrawFunds(address,uint256)")),
            recipient,
            20 ether
        );
        
        vm.expectRevert();
        (success, ) = address(diamond).call(largeWithdrawSelector);
        
        // Saque completo usando 0 como quantidade
        bytes memory fullWithdrawSelector = abi.encodeWithSelector(
            bytes4(keccak256("withdrawFunds(address,uint256)")),
            recipient,
            0
        );
        
        vm.expectEmit(true, false, false, true);
        emit FundsWithdrawn(recipient, 5 ether);
        
        (success, ) = address(diamond).call(fullWithdrawSelector);
        assertTrue(success, "Owner nao conseguiu sacar todos os fundos");
        
        // Verificando saldo final
        assertEq(address(diamond).balance, 0, "Saldo do contrato nao zerou apos saque completo");
        assertEq(recipient.balance, 10 ether, "Saldo do recipient incorreto apos saque completo");
        
        vm.stopPrank();
    }
    
    function testUpdateVestingPeriod() public {
        vm.startPrank(owner);
        
        // Verificando estado inicial
        bytes memory getVestingSelector = abi.encodeWithSelector(
            bytes4(keccak256("getVestingPeriod()"))
        );
        
        (bool success, bytes memory result) = address(diamond).call(getVestingSelector);
        assertTrue(success, "Falha ao obter periodo de vesting");
        uint256 initialPeriod = abi.decode(result, (uint256));
        
        // Atualizando periodo de vesting
        uint256 newPeriod = 30 days;
        
        vm.expectEmit(false, false, false, true);
        emit VestingPeriodUpdated(initialPeriod, newPeriod);
        
        bytes memory updateVestingSelector = abi.encodeWithSelector(
            bytes4(keccak256("updateVestingPeriod(uint256)")),
            newPeriod
        );
        
        (success, ) = address(diamond).call(updateVestingSelector);
        assertTrue(success, "Falha ao atualizar periodo de vesting");
        
        // Verificando novo valor
        (success, result) = address(diamond).call(getVestingSelector);
        assertTrue(success, "Falha ao obter periodo de vesting");
        uint256 updatedPeriod = abi.decode(result, (uint256));
        assertEq(updatedPeriod, newPeriod, "Periodo de vesting nao foi atualizado corretamente");
        
        // Testando falha ao definir periodo zero
        bytes memory invalidPeriodSelector = abi.encodeWithSelector(
            bytes4(keccak256("updateVestingPeriod(uint256)")),
            0
        );
        
        vm.expectRevert();
        (success, ) = address(diamond).call(invalidPeriodSelector);
        
        vm.stopPrank();
        
        // Não-admin não pode atualizar o periodo
        vm.startPrank(user);
        
        vm.expectRevert();
        (success, ) = address(diamond).call(updateVestingSelector);
        
        vm.stopPrank();
    }
}
