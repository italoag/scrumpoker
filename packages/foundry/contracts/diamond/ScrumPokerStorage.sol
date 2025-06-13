// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./library/StringUtils.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ScrumPokerStorage
 * @dev Contrato de armazenamento para o padrão Diamond do ScrumPoker.
 * Este contrato define todas as estruturas de dados e variáveis de estado
 * que serão compartilhadas entre as facetas do Diamond.
 *
 * Otimizações e características importantes:
 * 1. Versionamento de storage para facilitar atualizações futuras
 * 2. Uso de bytes32 em vez de strings para chaves de mapeamentos
 * 3. Organização eficiente das estruturas para minimizar o uso de gas
 * 4. Funções helpers para simplificar o acesso e manipulação dos dados
 */
library ScrumPokerStorage {
    using SafeERC20 for IERC20;
    using StringUtils for string;
    
    // Posições fixas e constantes do armazenamento
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("scrumpoker.storage.diamond");
    bytes32 constant DIAMOND_STORAGE_VERSION_POSITION = keccak256("scrumpoker.storage.version");
    
    // Versão atual do layout de armazenamento
    // Alterações no layout de storage devem ser acompanhadas de incremento na versão
    uint256 constant CURRENT_STORAGE_VERSION = 2;

    struct SprintResult {
        uint256 sprintNumber;         // Número do sprint
        uint256 startTime;            // Data/hora de início da cerimônia
        uint256 endTime;              // Data/hora de término da cerimônia
        uint256 totalPoints;          // Pontos acumulados (soma dos votos)
        string[] functionalityCodes;  // Códigos das funcionalidades votadas
        uint256[] functionalityVotes; // Pontuações recebidas em cada funcionalidade
    }

    struct BadgeData {
        string userName;              // Nome do usuário
        address userAddress;          // Endereço do usuário
        uint256 ceremoniesParticipated; // Quantidade de cerimônias em que participou
        uint256 votesCast;            // Número de votos realizados na votação geral
        SprintResult[] sprintResults; // Histórico dos resultados dos sprints
        string externalURI;           // URI para metadados externos (ex.: imagem/avatar)
    }

    /**
     * @dev Estrutura que representa uma cerimônia de Planning Poker.
     * Cada cerimônia tem um código único e armazena informações como o sprint,
     * os horários de início e fim, e a lista de participantes.
     */
    struct Ceremony {
        bytes32 codeHash;        // Hash do código para eficiência de gas
        string code;            // Código único da cerimônia (mantido para retrocompatibilidade)
        uint256 sprintNumber;   // Número do sprint associado
        uint256 startTime;      // Data/hora de início
        uint256 endTime;        // Data/hora de término (0 se não concluída)
        address scrumMaster;    // Endereço do Scrum Master (iniciador)
        bool active;            // Indica se a cerimônia está ativa
        address[] participants; // Lista de participantes aprovados
    }

    /**
     * @dev Estrutura para sessões de votação de funcionalidades específicas.
     * Cada sessão tem um código de funcionalidade e controla os votos dos participantes.
     */
    struct FunctionalityVoteSession {
        bytes32 functionalityCodeHash; // Hash do código de funcionalidade para eficiência de gas
        string functionalityCode;      // Código da funcionalidade votada (mantido para retrocompatibilidade)
        bool active;                   // Sessão de votação ativa
        // Controle de votos nesta sessão: participante => bool (se votou)
        mapping(address => bool) hasVoted;
        // Armazena o voto do participante nesta sessão: participante => valor
        mapping(address => uint256) votes;
    }

    /**
     * @dev Estrutura principal de armazenamento seguindo o padrão Diamond.
     * Armazena todos os dados compartilhados entre as várias facetas do contrato.
     * Inclui informações de versionamento para facilitar atualizações futuras.
     */
    struct DiamondStorage {
        // Informações de versionamento
        uint256 version;                 // Versão atual do layout de armazenamento
        uint256 lastUpgradeTimestamp;    // Timestamp da última atualização de layout

        // Configurações Gerais
        uint256 exchangeRate;            // Valor (em wei) equivalente a 1 dólar
        uint256 lastExchangeRateUpdate;  // Timestamp da última atualização da cotação
        uint256 vestingPeriod;          // Período de vesting em segundos (ex.: 1 dia = 86400)
        uint256 nextTokenId;             // Contador para geração dos tokenIds (primeiro NFT terá tokenId 1)
        bool paused;                     // Flag para pausar o contrato em caso de emergência
        address priceOracle;             // Endereço do oráculo de preços
        uint256 ceremonyCounter;         // Contador para gerar códigos únicos de cerimônias

        // Mapeamentos de NFT e Vesting
        mapping(address => uint256) userToken;       // Endereço => tokenId do NFT
        mapping(address => uint256) vestingStart;    // Endereço => timestamp início vesting
        mapping(uint256 => BadgeData) badgeData;    // TokenId => metadados do badge

        // Mapeamentos otimizados para Cerimônias - usando bytes32 para chaves
        mapping(bytes32 => Ceremony) ceremoniesByHash;    // Hash do código => cerimônia
        mapping(string => bytes32) ceremonyCodeToHash;   // Código => hash (para retrocompatibilidade)
        mapping(bytes32 => bool) ceremonyExists;          // Hash do código => existe
        
        // Controles de cerimônia otimizados (usando bytes32)
        mapping(bytes32 => mapping(address => bool)) hasRequestedEntry;   // Hash => (endereço => solicitou)
        mapping(bytes32 => mapping(address => bool)) ceremonyApproved;    // Hash => (endereço => aprovado)
        mapping(bytes32 => mapping(address => bool)) ceremonyHasVoted;    // Hash => (endereço => votou)
        mapping(bytes32 => mapping(address => uint256)) ceremonyVotes;   // Hash => (endereço => valor)

        // Votações de Funcionalidades (otimizado)
        mapping(bytes32 => FunctionalityVoteSession[]) functionalityVoteSessions; // Hash => sessões

        // Controle de Acesso
        mapping(bytes32 => mapping(address => bool)) roles; // Role => (endereço => tem papel)
        
    }

    // Constantes para controle de acesso baseado em papéis
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 constant SCRUM_MASTER_ROLE = keccak256("SCRUM_MASTER_ROLE");
    bytes32 constant PRICE_UPDATER_ROLE = keccak256("PRICE_UPDATER_ROLE");
    
    // Erros personalizados
    error StorageNotInitialized();
    error StorageVersionMismatch(uint256 expected, uint256 actual);
    error CeremonyNotFound(string code);
    error CeremonyAlreadyExists(string code);

    /**
     * @dev Obtém a referência para o storage principal do contrato Diamond.
     * @return ds Referência ao storage principal.
     */
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    
    /**
     * @dev Obtém a versão atual do layout de storage.
     * @return Versão atual do layout de storage.
     */
    function getStorageVersion() internal view returns (uint256) {
        return diamondStorage().version;
    }
    
    /**
     * @dev Atualiza a versão do layout de storage.
     * @dev Esta função só deve ser chamada após atualizações estruturais do contrato.
     */
    function upgradeStorageVersion() internal {
        DiamondStorage storage ds = diamondStorage();
        ds.version = CURRENT_STORAGE_VERSION;
        ds.lastUpgradeTimestamp = block.timestamp;
    }
    
    /**
     * @dev Verifica se o layout de storage está atualizado.
     * @return Verdadeiro se o layout estiver na versão mais recente.
     */
    function isStorageUpToDate() internal view returns (bool) {
        return getStorageVersion() == CURRENT_STORAGE_VERSION;
    }
    
    /**
     * @dev Registra o hash de um código de cerimônia para posterior consulta.
     * @param code Código da cerimônia.
     * @return Hash do código em formato bytes32.
     */
    function registerCeremonyCode(string memory code) internal returns (bytes32) {
        DiamondStorage storage ds = diamondStorage();
        bytes32 codeHash = code.stringToBytes32();
        ds.ceremonyCodeToHash[code] = codeHash;
        return codeHash;
    }
    
    /**
     * @dev Obtém o hash de um código de cerimônia, registrando-o se não existir.
     * @param code Código da cerimônia.
     * @return Hash do código em formato bytes32.
     */
    function getCeremonyCodeHash(string memory code) internal returns (bytes32) {
        DiamondStorage storage ds = diamondStorage();
        bytes32 codeHash = ds.ceremonyCodeToHash[code];
        
        // Se o hash ainda não está registrado, registre-o
        if (codeHash == bytes32(0)) {
            codeHash = registerCeremonyCode(code);
        }
        
        return codeHash;
    }
    
    /**
     * @dev Obtém o hash de um código de cerimônia sem modificar o storage (view function).
     * @param code Código da cerimônia.
     * @return Hash do código em formato bytes32.
     */
    function getCeremonyCodeHashView(string memory code) internal view returns (bytes32) {
        DiamondStorage storage ds = diamondStorage();
        bytes32 codeHash = ds.ceremonyCodeToHash[code];
        
        // Se o hash não está registrado, calcule-o sem armazenar
        if (codeHash == bytes32(0)) {
            codeHash = code.stringToBytes32();
        }
        
        return codeHash;
    }
    
    /**
     * @dev Inicializa o armazenamento com a versão atual ou verifica se já está inicializado.
     * Deve ser chamado durante a inicialização do contrato para garantir o versionamento.
     */
    function initializeStorage() internal {
        DiamondStorage storage ds = diamondStorage();
        
        // Se o storage está vazio, inicialize com a versão atual
        if (ds.version == 0) {
            ds.version = CURRENT_STORAGE_VERSION;
            ds.lastUpgradeTimestamp = block.timestamp;
        }
    }
    
    /**
     * @dev Verifica se o storage está inicializado e na versão correta.
     * Reverte se não estiver inicializado ou na versão esperada.
     */
    function requireCorrectStorageVersion() internal view {
        DiamondStorage storage ds = diamondStorage();
        
        if (ds.version == 0) {
            revert StorageNotInitialized();
        }
        
        if (ds.version != CURRENT_STORAGE_VERSION) {
            revert StorageVersionMismatch(CURRENT_STORAGE_VERSION, ds.version);
        }
    }
    
    /**
     * @dev Verifica a existência de uma cerimônia usando o hash do código.
     * @param codeHash Hash do código da cerimônia.
     * @return Verdadeiro se a cerimônia existe.
     */
    function ceremoniesExistsByHash(bytes32 codeHash) internal view returns (bool) {
        return diamondStorage().ceremonyExists[codeHash];
    }
    
    /**
     * @dev Verifica a existência de uma cerimônia usando o código como string.
     * Suporta tanto o novo formato otimizado quanto o legado.
     * @param code Código da cerimônia.
     * @return Verdadeiro se a cerimônia existe.
     */
    function ceremonyExists(string memory code) internal view returns (bool) {
        bytes32 codeHash = getCeremonyCodeHashView(code);
        return ceremoniesExistsByHash(codeHash);
    }
    
    /**
     * @dev Obtém uma cerimônia pelo hash do código.
     * @param codeHash Hash do código da cerimônia.
     * @return Estrutura da cerimônia.
     */
    function getCeremonyByHash(bytes32 codeHash) internal view returns (Ceremony storage) {
        // Obter a cerimônia do novo formato otimizado
        return diamondStorage().ceremoniesByHash[codeHash];
    }
    
    /**
     * @dev Obtém uma cerimônia pelo código (string).
     * Suporta tanto o novo formato otimizado quanto o legado.
     * @param code Código da cerimônia.
     * @return Estrutura da cerimônia.
     */
    function getCeremony(string memory code) internal view returns (Ceremony storage) {
        bytes32 codeHash = getCeremonyCodeHashView(code);
        return diamondStorage().ceremoniesByHash[codeHash];
    }

    
}