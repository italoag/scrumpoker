// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ScrumPokerStorage
 * @dev Contrato de armazenamento para o padrão Diamond do ScrumPoker.
 * Este contrato define todas as estruturas de dados e variáveis de estado
 * que serão compartilhadas entre as facetas do Diamond.
 */
library ScrumPokerStorage {
    using SafeERC20 for IERC20;

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("scrumpoker.storage.diamond");

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

    struct Ceremony {
        string code;            // Código único da cerimônia
        uint256 sprintNumber;   // Número do sprint associado
        uint256 startTime;      // Data/hora de início
        uint256 endTime;        // Data/hora de término (0 se não concluída)
        address scrumMaster;    // Endereço do Scrum Master (iniciador)
        bool active;            // Indica se a cerimônia está ativa
        address[] participants; // Lista de participantes aprovados
    }

    struct FunctionalityVoteSession {
        string functionalityCode; // Código da funcionalidade votada
        bool active;              // Sessão de votação ativa
        // Controle de votos nesta sessão: participante => bool (se votou)
        mapping(address => bool) hasVoted;
        // Armazena o voto do participante nesta sessão: participante => valor
        mapping(address => uint256) votes;
    }

    struct DiamondStorage {
        // Configurações Gerais
        // Valor (em wei) equivalente a 1 dólar – pode ser atualizado pelo owner.
        uint256 exchangeRate;
        // Timestamp da última atualização da cotação.
        uint256 lastExchangeRateUpdate;
        // Período de vesting (em segundos); por exemplo, 1 dia = 86400.
        uint256 vestingPeriod;
        // Contador para geração dos tokenIds (primeiro NFT terá tokenId 1)
        uint256 nextTokenId;
        // Flag para pausar o contrato em caso de emergência
        bool paused;
        // Endereço do oráculo de preços
        address priceOracle;

        // Mapeamentos de NFT e Vesting
        // Associa cada endereço ao tokenId do NFT adquirido (cada usuário possui um NFT)
        mapping(address => uint256) userToken;
        // Registra o timestamp de início do vesting para cada usuário
        mapping(address => uint256) vestingStart;
        // Mapeia o tokenId do NFT para seus metadados dinâmicos.
        mapping(uint256 => BadgeData) badgeData;

        // Estruturas e Dados das Cerimônias (Sprints)
        // Mapeia o código da cerimônia para a estrutura
        mapping(string => Ceremony) ceremonies;
        // Indica se uma cerimônia existe (código => bool)
        mapping(string => bool) ceremonyExists;
        // Contador para gerar códigos únicos de cerimônias.
        uint256 ceremonyCounter;
        // Controle de solicitação de entrada: cerimônia => (usuário => bool)
        mapping(string => mapping(address => bool)) hasRequestedEntry;
        // Controle de aprovação: cerimônia => (usuário => bool)
        mapping(string => mapping(address => bool)) ceremonyApproved;
        // Controle de voto geral: cerimônia => (usuário => bool)
        mapping(string => mapping(address => bool)) ceremonyHasVoted;
        // Armazena o voto geral de cada participante: cerimônia => (usuário => valor)
        mapping(string => mapping(address => uint256)) ceremonyVotes;

        // Votações de Funcionalidades (Sessões)
        // Mapeia cada código de cerimônia para um array de sessões de votação.
        mapping(string => FunctionalityVoteSession[]) functionalityVoteSessions;

        // Controle de Acesso
        // Mapeamento de papéis (role => address => bool)
        mapping(bytes32 => mapping(address => bool)) roles;
    }

    // Constantes para controle de acesso baseado em papéis
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 constant SCRUM_MASTER_ROLE = keccak256("SCRUM_MASTER_ROLE");
    bytes32 constant PRICE_UPDATER_ROLE = keccak256("PRICE_UPDATER_ROLE");

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}