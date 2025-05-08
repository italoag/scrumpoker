// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {AdminFacet} from "../contracts/diamond/facets/AdminFacet.sol";
import {ScrumPokerStorage} from "../contracts/diamond/ScrumPokerStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Mock IERC20 para testes
contract MockERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    
    function mint(address account, uint256 amount) external {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }
    function decimals() external pure returns (uint8) { return 18; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }
    
    function transfer(address to, uint256 amount) external override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        address owner = msg.sender;
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
    
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _allowances[owner][spender] = currentAllowance - amount;
        }
    }
}

// Eventos para testes
event VestingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
event FundsWithdrawn(address indexed to, uint256 amount);
event ERC20TokensWithdrawn(address indexed token, address indexed to, uint256 amount);
event PriceOracleUpdated(address indexed newOracle);

contract AdminFacetTest is Test {
    AdminFacet adminFacet;
    address owner = address(0xABCD);
    address user = address(0x1234);
    address recipient = address(0x5555);
    uint256 initialRate = 1e18;
    uint256 vestingPeriod = 30 days;
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 constant PRICE_UPDATER_ROLE = keccak256("PRICE_UPDATER_ROLE");
    
    // Contrato Mock ERC20 para testes
    MockERC20 mockToken;

    // Inicialização dos testes com controle de estado
    function setUp() public {
        // Deploy do contrato AdminFacet
        adminFacet = new AdminFacet();
        
        // Inicialização com os parâmetros base
        adminFacet.initialize(initialRate, vestingPeriod, owner);
        
        // Deploy do token mock para testes de withdrawERC20
        mockToken = new MockERC20("Mock Token", "MOCK");
    }

    // Verifica se a inicialização configura corretamente os valores e papéis
    function testInitializeSetsState() public view {
        uint256 rate = adminFacet.getExchangeRate();
        uint256 period = adminFacet.getVestingPeriod();
        assertEq(rate, initialRate, unicode"Taxa de cambio inicial incorreta");
        assertEq(period, vestingPeriod, unicode"Periodo de vesting inicial incorreto");
        assertTrue(adminFacet.hasRole(ADMIN_ROLE, owner), unicode"Owner nao recebeu ADMIN_ROLE");
        assertTrue(adminFacet.hasRole(PRICE_UPDATER_ROLE, owner), unicode"Owner nao recebeu PRICE_UPDATER_ROLE");
    }

    // Verifica se um administrador pode atualizar a taxa de câmbio
    function testUpdateExchangeRateByAdmin() public {
        vm.prank(owner);
        adminFacet.updateExchangeRate(2e18);
        uint256 rate = adminFacet.getExchangeRate();
        assertEq(rate, 2e18, unicode"Taxa de cambio nao foi atualizada corretamente");
    }

    // Verifica se um não-administrador não pode atualizar a taxa de câmbio
    function testUpdateExchangeRateByNonAdminReverts() public {
        vm.prank(user);
        vm.expectRevert();
        adminFacet.updateExchangeRate(2e18);
    }

    // Verifica as funções de pause e unpause
    function testPauseAndUnpause() public {
        vm.startPrank(owner);
        
        // Verificar estado inicial
        assertFalse(adminFacet.isPaused(), unicode"Contrato ja esta pausado inicialmente");
        
        // Pausar o contrato
        adminFacet.pause();
        
        // Verificar se está pausado usando a função isPaused()
        assertTrue(adminFacet.isPaused(), unicode"Contrato nao foi pausado corretamente");
        
        // Despausar o contrato
        adminFacet.unpause();
        
        // Verificar se está despausado
        assertFalse(adminFacet.isPaused(), unicode"Contrato nao foi despausado corretamente");
        
        vm.stopPrank();
    }

    // Verifica grant e revoke de papéis
    function testGrantAndRevokeRole() public {
        vm.startPrank(owner);
        
        // Conceder papel a um usuário
        adminFacet.grantRole(ADMIN_ROLE, user);
        assertTrue(adminFacet.hasRole(ADMIN_ROLE, user), unicode"Papel nao foi concedido corretamente");
        
        // Revogar papel
        adminFacet.revokeRole(ADMIN_ROLE, user);
        assertFalse(adminFacet.hasRole(ADMIN_ROLE, user), unicode"Papel nao foi revogado corretamente");
        
        vm.stopPrank();
    }

    // Verifica a configuração do oráculo de preços
    function testSetPriceOracle() public {
        address oracle = address(0xBEEF);
        
        // Verificar evento sendo emitido
        vm.expectEmit(true, false, false, false);
        emit PriceOracleUpdated(oracle);
        
        vm.prank(owner);
        // Definir o oráculo de preços
        adminFacet.setPriceOracle(oracle);
        
        // Não podemos verificar o storage diretamente em teste de unidade
        // já que é um teste da faceta isolada e não há conexão real com o storage do Diamond
        // Verificamos apenas se a função executa sem reverter e se o evento é emitido
    }

    // Verifica se inicialização com endereço zero falha
    function testZeroAddressReverts() public {
        AdminFacet newAdminFacet = new AdminFacet();
        vm.expectRevert();
        newAdminFacet.initialize(initialRate, vestingPeriod, address(0));
    }
    
    // NOVOS TESTES PARA AS FUNCIONALIDADES IMPLEMENTADAS
    
    // Testa a atualização do período de vesting
    function testUpdateVestingPeriod() public {
        uint256 newPeriod = 60 days;
        
        vm.startPrank(owner);
        
        // Capturar o evento
        vm.expectEmit(false, false, false, true);
        emit VestingPeriodUpdated(vestingPeriod, newPeriod);
        
        // Atualizar o período
        adminFacet.updateVestingPeriod(newPeriod);
        
        // Verificar se foi atualizado
        uint256 updatedPeriod = adminFacet.getVestingPeriod();
        assertEq(updatedPeriod, newPeriod, unicode"Periodo de vesting nao foi atualizado corretamente");
        
        vm.stopPrank();
    }
    
    // Testa atualização inválida (zero) do período de vesting
    function testUpdateVestingPeriodWithZeroReverts() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(AdminFacet.InvalidVestingPeriod.selector));
        adminFacet.updateVestingPeriod(0);
    }
    
    // Testa que apenas admin pode atualizar o período de vesting
    function testUpdateVestingPeriodByNonAdminReverts() public {
        vm.prank(user);
        vm.expectRevert();
        adminFacet.updateVestingPeriod(60 days);
    }
    
    // Testa a função withdrawFunds
    function testWithdrawFunds() public {
        // Preparar o contrato com ETH
        vm.deal(address(adminFacet), 10 ether);
        assertEq(address(adminFacet).balance, 10 ether, "Saldo inicial incorreto");
        
        address payable recipientAddr = payable(recipient);
        uint256 amountToWithdraw = 5 ether;
        
        vm.startPrank(owner);
        
        // Verificar evento
        vm.expectEmit(true, false, false, true);
        emit FundsWithdrawn(recipientAddr, amountToWithdraw);
        
        // Sacar parcialmente
        adminFacet.withdrawFunds(recipientAddr, amountToWithdraw);
        
        // Verificar saldos
        assertEq(address(adminFacet).balance, 5 ether, unicode"Saldo do contrato incorreto apos saque");
        assertEq(recipientAddr.balance, 5 ether, unicode"Saldo do destinatario incorreto apos saque");
        
        // Sacar tudo (usando 0)
        adminFacet.withdrawFunds(recipientAddr, 0);
        
        // Verificar saldos finais
        assertEq(address(adminFacet).balance, 0, unicode"Saldo do contrato nao zerou apos saque completo");
        assertEq(recipientAddr.balance, 10 ether, unicode"Saldo do destinatario incorreto apos saque completo");
        
        vm.stopPrank();
    }
    
    // Testa saque excedendo o saldo
    function testWithdrawFundsExceedingBalanceReverts() public {
        // Preparar contrato com ETH
        vm.deal(address(adminFacet), 1 ether);
        
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(
            AdminFacet.InsufficientFunds.selector,
            5 ether,
            1 ether
        ));
        adminFacet.withdrawFunds(payable(recipient), 5 ether);
    }
    
    // Testa que não-admin não pode sacar fundos
    function testWithdrawFundsByNonAdminReverts() public {
        vm.deal(address(adminFacet), 1 ether);
        
        vm.prank(user);
        vm.expectRevert();
        adminFacet.withdrawFunds(payable(recipient), 0.5 ether);
    }
    
    // Testa saque de tokens ERC20
    function testWithdrawERC20() public {
        // Preparar tokens no contrato
        uint256 tokenAmount = 1000 * 10**18;
        mockToken.mint(address(adminFacet), tokenAmount);
        
        assertEq(mockToken.balanceOf(address(adminFacet)), tokenAmount, unicode"Saldo inicial de tokens incorreto");
        
        uint256 withdrawAmount = 400 * 10**18;
        
        vm.startPrank(owner);
        
        // Verificar evento
        vm.expectEmit(true, true, false, true);
        emit ERC20TokensWithdrawn(address(mockToken), recipient, withdrawAmount);
        
        // Sacar tokens parcialmente
        adminFacet.withdrawERC20(address(mockToken), recipient, withdrawAmount);
        
        // Verificar saldos
        assertEq(mockToken.balanceOf(address(adminFacet)), tokenAmount - withdrawAmount, unicode"Saldo de tokens do contrato incorreto apos saque");
        assertEq(mockToken.balanceOf(recipient), withdrawAmount, unicode"Saldo de tokens do destinatario incorreto apos saque");
        
        // Sacar todos os tokens restantes (usando 0)
        adminFacet.withdrawERC20(address(mockToken), recipient, 0);
        
        // Verificar saldos finais
        assertEq(mockToken.balanceOf(address(adminFacet)), 0, unicode"Saldo de tokens do contrato nao zerou apos saque completo");
        assertEq(mockToken.balanceOf(recipient), tokenAmount, unicode"Saldo de tokens do destinatario incorreto apos saque completo");
        
        vm.stopPrank();
    }
    
    // Testa saque de ERC20 excedendo saldo
    function testWithdrawERC20ExceedingBalanceReverts() public {
        uint256 tokenAmount = 100 * 10**18;
        mockToken.mint(address(adminFacet), tokenAmount);
        
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(
            AdminFacet.InsufficientFunds.selector,
            200 * 10**18,
            tokenAmount
        ));
        adminFacet.withdrawERC20(address(mockToken), recipient, 200 * 10**18);
    }
    
    // Testa que não-admin não pode sacar tokens ERC20
    function testWithdrawERC20ByNonAdminReverts() public {
        mockToken.mint(address(adminFacet), 100 * 10**18);
        
        vm.prank(user);
        vm.expectRevert();
        adminFacet.withdrawERC20(address(mockToken), recipient, 50 * 10**18);
    }
}