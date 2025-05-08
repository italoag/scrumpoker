// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../ScrumPokerStorage.sol";

/**
 * @title AdminFacet
 * @dev Faceta de administração para o contrato ScrumPoker Diamond.
 * Contém funções para gerenciar configurações, pausar/despausar o contrato,
 * e inicializar o armazenamento compartilhado.
 */
contract AdminFacet is Initializable {
    using SafeERC20 for IERC20;

    event ExchangeRateUpdated(uint256 newRate, uint256 timestamp);
    event CotacaoOutdated(uint256 lastUpdated);
    event ContractPaused(address operator);
    event ContractUnpaused(address operator);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event PriceOracleUpdated(address indexed newOracle);

    error NotAuthorized();
    error ZeroAddress();

    /**
     * @dev Modificador que verifica se o chamador tem um papel específico.
     * @param role O papel a ser verificado.
     */
    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) revert NotAuthorized();
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
        if (_admin == address(0)) revert ZeroAddress();
        
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
    function updateExchangeRate(uint256 newRate) external onlyRole(ScrumPokerStorage.PRICE_UPDATER_ROLE) {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        ds.exchangeRate = newRate;
        ds.lastExchangeRateUpdate = block.timestamp;
        emit ExchangeRateUpdated(newRate, block.timestamp);
    }

    /**
     * @notice Define o endereço do oráculo de preços.
     * @param _priceOracle Endereço do oráculo de preços.
     */
    function setPriceOracle(address _priceOracle) external onlyRole(ScrumPokerStorage.ADMIN_ROLE) {
        if (_priceOracle == address(0)) revert ZeroAddress();
        ScrumPokerStorage.diamondStorage().priceOracle = _priceOracle;
        emit PriceOracleUpdated(_priceOracle);
    }

    /**
     * @notice Pausa o contrato em caso de emergência.
     */
    function pause() external onlyRole(ScrumPokerStorage.ADMIN_ROLE) whenNotPaused {
        ScrumPokerStorage.diamondStorage().paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Despausa o contrato após uma emergência.
     */
    function unpause() external onlyRole(ScrumPokerStorage.ADMIN_ROLE) whenPaused {
        ScrumPokerStorage.diamondStorage().paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @notice Concede um papel a um endereço.
     * @param role O papel a ser concedido.
     * @param account O endereço que receberá o papel.
     */
    function grantRole(bytes32 role, address account) external onlyRole(ScrumPokerStorage.ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @notice Revoga um papel de um endereço.
     * @param role O papel a ser revogado.
     * @param account O endereço que perderá o papel.
     */
    function revokeRole(bytes32 role, address account) external onlyRole(ScrumPokerStorage.ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @notice Verifica se um endereço tem um papel específico.
     * @param role O papel a ser verificado.
     * @param account O endereço a ser verificado.
     * @return bool Verdadeiro se o endereço tiver o papel.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return ScrumPokerStorage.diamondStorage().roles[role][account];
    }

    /**
     * @dev Concede um papel a um endereço.
     * @param role O papel a ser concedido.
     * @param account O endereço que receberá o papel.
     */
    function _grantRole(bytes32 role, address account) internal {
        ScrumPokerStorage.diamondStorage().roles[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @dev Revoga um papel de um endereço.
     * @param role O papel a ser revogado.
     * @param account O endereço que perderá o papel.
     */
    function _revokeRole(bytes32 role, address account) internal {
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
     * @notice Verifica se o contrato está pausado.
     * @return bool Verdadeiro se o contrato estiver pausado.
     */
    function isPaused() external view returns (bool) {
        return ScrumPokerStorage.diamondStorage().paused;
    }
}