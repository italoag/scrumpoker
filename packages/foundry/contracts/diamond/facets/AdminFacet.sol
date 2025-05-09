// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../ScrumPokerStorage.sol";
import "../library/ValidationUtils.sol";

/**
 * @title AdminFacet
 * @dev Faceta de administração para o contrato ScrumPoker Diamond.
 * Contém funções para gerenciar configurações, pausar/despausar o contrato,
 * controle de acesso baseado em papéis (RBAC) e funcionalidades de emergência.
 * 
 * Esta faceta implementa:
 * - Inicialização do contrato e configurações
 * - Controle de pausa/despausa do sistema
 * - Gerenciamento de papéis (admin, price updater, etc)
 * - Funções de emergência para saques
 * - Atualização de taxas e parâmetros do sistema
 */
contract AdminFacet is Initializable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using ValidationUtils for address;
    using ValidationUtils for uint256;

    // Eventos para rastreabilidade de ações administrativas
    event ExchangeRateUpdated(uint256 newRate, uint256 timestamp);
    event QuoteOutdated(uint256 lastUpdated);
    event ContractPaused(address indexed operator);
    event ContractUnpaused(address indexed operator);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event PriceOracleUpdated(address indexed newOracle);
    event VestingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event ERC20TokensWithdrawn(address indexed token, address indexed to, uint256 amount);
    
    // Erros personalizados para mensagens mais claras
    error NotAuthorized();
    error ZeroAddress();
    error InsufficientFunds(uint256 requested, uint256 available);
    error InvalidVestingPeriod();
    error TransferFailed();

    /**
     * @dev Modificador que verifica se o chamador tem um papel específico.
     * @param role O papel a ser verificado.
     */
    modifier onlyRole(bytes32 role) {
        if (!ScrumPokerStorage.diamondStorage().roles[role][msg.sender]) revert NotAuthorized();
        _;
    }

    /**
     * @dev Modificador que verifica se o contrato não está pausado.
     */
    modifier whenNotPaused() {
        require(!ScrumPokerStorage.diamondStorage().paused, "AdminFacet: pausado");
        _;
    }

    /**
     * @dev Modificador que verifica se o contrato está pausado.
     */
    modifier whenPaused() {
        require(ScrumPokerStorage.diamondStorage().paused, "AdminFacet: nao pausado");
        _;
    }

    /**
     * @dev Inicializa o contrato ScrumPoker.
     * @param _initialExchangeRate Taxa de câmbio inicial (valor em wei equivalente a 1 dólar).
     * @param _vestingPeriod Período de vesting em segundos.
     * @param _admin Endereço do administrador inicial.
     */
    function initialize(
        uint256 _initialExchangeRate,
        uint256 _vestingPeriod,
        address _admin
    ) external initializer {
        ValidationUtils.requireNotZeroAddress(_admin, "Admin address cannot be zero");
        
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        ds.exchangeRate = _initialExchangeRate;
        ds.lastExchangeRateUpdate = block.timestamp;
        ds.vestingPeriod = _vestingPeriod;
        ds.nextTokenId = 0;
        ds.ceremonyCounter = 1;
        ds.paused = false;
        
        // Concede papel de administrador ao endereço fornecido
        _grantRole(ScrumPokerStorage.ADMIN_ROLE, _admin);
        _grantRole(ScrumPokerStorage.PRICE_UPDATER_ROLE, _admin);
    }

    /**
     * @notice Atualiza a cotação do token nativo para 1 dólar.
     * @param newRate Novo valor (em wei) equivalente a 1 dólar.
     */
    function updateExchangeRate(uint256 newRate) external nonReentrant onlyRole(ScrumPokerStorage.PRICE_UPDATER_ROLE) {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        ds.exchangeRate = newRate;
        ds.lastExchangeRateUpdate = block.timestamp;
        emit ExchangeRateUpdated(newRate, block.timestamp);
    }

    /**
     * @notice Define o endereço do oráculo de preços.
     * @param _priceOracle Endereço do oráculo de preços.
     */
    function setPriceOracle(address _priceOracle) external nonReentrant onlyRole(ScrumPokerStorage.ADMIN_ROLE) {
        ValidationUtils.requireNotZeroAddress(_priceOracle, "Price oracle address cannot be zero");
        ScrumPokerStorage.diamondStorage().priceOracle = _priceOracle;
        emit PriceOracleUpdated(_priceOracle);
    }

    /**
     * @notice Pausa o contrato em caso de emergência.
     */
    function pause() external nonReentrant onlyRole(ScrumPokerStorage.ADMIN_ROLE) whenNotPaused {
        ScrumPokerStorage.diamondStorage().paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Despausa o contrato após uma emergência.
     */
    function unpause() external nonReentrant onlyRole(ScrumPokerStorage.ADMIN_ROLE) whenPaused {
        ScrumPokerStorage.diamondStorage().paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @notice Concede um papel a um endereço.
     * @param role O papel a ser concedido.
     * @param account O endereço que receberá o papel.
     */
    function grantRole(bytes32 role, address account) external nonReentrant onlyRole(ScrumPokerStorage.ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @notice Revoga um papel de um endereço.
     * @param role O papel a ser revogado.
     * @param account O endereço que perderá o papel.
     */
    function revokeRole(bytes32 role, address account) external nonReentrant onlyRole(ScrumPokerStorage.ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @notice Verifica se um endereço tem um papel específico.
     * @param role O papel a ser verificado.
     * @param account O endereço a ser verificado.
     * @return bool Verdadeiro se o endereço tiver o papel.
     */
    function hasRole(bytes32 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }
    
    /**
     * @dev Verificação interna se um endereço tem um papel específico.
     * @param role O papel a ser verificado.
     * @param account O endereço a ser verificado.
     * @return bool Verdadeiro se o endereço tiver o papel.
     */
    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return ScrumPokerStorage.diamondStorage().roles[role][account];
    }

    /**
     * @dev Concede um papel a um endereço.
     * @param role O papel a ser concedido.
     * @param account O endereço que receberá o papel.
     */
    function _grantRole(bytes32 role, address account) internal {
        ValidationUtils.requireNotZeroAddress(account, "Account address cannot be zero");
        ScrumPokerStorage.diamondStorage().roles[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @dev Revoga um papel de um endereço.
     * @param role O papel a ser revogado.
     * @param account O endereço que perderá o papel.
     */
    function _revokeRole(bytes32 role, address account) internal {
        ValidationUtils.requireNotZeroAddress(account, "Account address cannot be zero");
        ScrumPokerStorage.diamondStorage().roles[role][account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice Obtém a taxa de câmbio atual.
     * @return uint256 Taxa de câmbio atual.
     */
    function getExchangeRate() external view returns (uint256) {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        // Removido: emissão de evento não permitida em função view
        return ds.exchangeRate;
    }

    /**
     * @notice Obtém o período de vesting.
     * @return uint256 Período de vesting em segundos.
     */
    function getVestingPeriod() external view returns (uint256) {
        return ScrumPokerStorage.diamondStorage().vestingPeriod;
    }
    
    /**
     * @notice Atualiza o período de vesting.
     * @param _newVestingPeriod Novo período de vesting em segundos.
     * @dev Apenas administradores podem atualizar este parâmetro.
     */
    function updateVestingPeriod(uint256 _newVestingPeriod) external nonReentrant onlyRole(ScrumPokerStorage.ADMIN_ROLE) {
        ValidationUtils.requireGreaterThanZero(_newVestingPeriod, "Vesting period must be greater than zero");
        
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        uint256 oldPeriod = ds.vestingPeriod;
        ds.vestingPeriod = _newVestingPeriod;
        
        emit VestingPeriodUpdated(oldPeriod, _newVestingPeriod);
    }

    /**
     * @notice Verifica se o contrato está pausado.
     * @return bool Verdadeiro se o contrato estiver pausado.
     */
    function isPaused() external view returns (bool) {
        return ScrumPokerStorage.diamondStorage().paused;
    }
    
    /**
     * @notice Função de emergência para sacar ETH do contrato.
     * @param _to Endereço para enviar os fundos.
     * @param _amount Quantidade de ETH a ser retirada. Use 0 para sacar todo o saldo.
     * @dev Esta função pode ser chamada mesmo quando o contrato está pausado.
     */
    function withdrawFunds(address payable _to, uint256 _amount) external nonReentrant onlyRole(ScrumPokerStorage.ADMIN_ROLE) {
        ValidationUtils.requireNotZeroAddress(_to, "Recipient address cannot be zero");
        
        uint256 balance = address(this).balance;
        uint256 amountToWithdraw = _amount == 0 ? balance : _amount;
        
        if (amountToWithdraw > balance) revert InsufficientFunds(amountToWithdraw, balance);
        
        (bool success, ) = _to.call{value: amountToWithdraw}("");
        if (!success) revert TransferFailed();
        
        emit FundsWithdrawn(_to, amountToWithdraw);
    }
    
    /**
     * @notice Função de emergência para sacar tokens ERC20 do contrato.
     * @param _token Endereço do contrato de token ERC20.
     * @param _to Endereço para enviar os tokens.
     * @param _amount Quantidade de tokens a ser retirada. Use 0 para sacar todo o saldo.
     * @dev Esta função pode ser chamada mesmo quando o contrato está pausado.
     */
    function withdrawERC20(address _token, address _to, uint256 _amount) external nonReentrant onlyRole(ScrumPokerStorage.ADMIN_ROLE) {
        ValidationUtils.requireNotZeroAddress(_token, "Token address cannot be zero");
        ValidationUtils.requireNotZeroAddress(_to, "Recipient address cannot be zero");
        
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        uint256 amountToWithdraw = _amount == 0 ? balance : _amount;
        
        if (amountToWithdraw > balance) revert InsufficientFunds(amountToWithdraw, balance);
        
        token.safeTransfer(_to, amountToWithdraw);
        
        emit ERC20TokensWithdrawn(_token, _to, amountToWithdraw);
    }
}