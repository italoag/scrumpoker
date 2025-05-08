// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../ScrumPokerStorage.sol";

/**
 * @title VotingFacet
 * @dev Faceta para gerenciar as votações e resultados das cerimônias do ScrumPoker.
 * Implementa a votação geral, votação de funcionalidades e atualização dos badges NFT.
 */
contract VotingFacet is Initializable, ReentrancyGuardUpgradeable {
    // Eventos
    event VoteCast(string ceremonyCode, address indexed participant, uint256 voteValue);
    event FunctionalityVoteOpened(string ceremonyCode, string functionalityCode, uint256 sessionIndex);
    event FunctionalityVoteCast(string ceremonyCode, uint256 sessionIndex, address indexed participant, uint256 voteValue);
    event NFTBadgeUpdated(address indexed participant, uint256 tokenId, uint256 sprintNumber);

    // Erros
    error CeremonyNotFound();
    error CeremonyNotActive();
    error NotAuthorized();
    error ParticipantNotApproved();
    error AlreadyVoted();
    error NFTNotVested();
    error SessionNotFound();
    error SessionNotActive();

    /**
     * @dev Modificador que verifica se o chamador tem um papel específico.
     * @param role O papel a ser verificado.
     */
    modifier onlyRole(bytes32 role) {
        if (!_hasRole(role, msg.sender)) revert NotAuthorized();
        _;
    }

    /**
     * @dev Modificador que verifica se o contrato não está pausado.
     */
    modifier whenNotPaused() {
        require(!ScrumPokerStorage.diamondStorage().paused, "VotingFacet: pausado");
        _;
    }

    /**
     * @dev Inicializa o contrato VotingFacet.
     */
    function initializeVoting() external initializer {
        __ReentrancyGuard_init();
    }

    /**
     * @notice Permite que um participante emita seu voto geral na cerimônia.
     * @param _code Código único da cerimônia.
     * @param _voteValue Valor do voto (pontos).
     * Requisitos:
     * - A cerimônia deve estar ativa.
     * - O participante deve estar aprovado.
     * - Não pode ter votado anteriormente.
     * - O NFT deve estar "vested" (após o período de vesting).
     */
    function vote(string memory _code, uint256 _voteValue) external whenNotPaused {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        if (!ds.ceremonyExists[_code]) revert CeremonyNotFound();
        if (!ds.ceremonies[_code].active) revert CeremonyNotActive();
        if (!ds.ceremonyApproved[_code][msg.sender]) revert ParticipantNotApproved();
        if (ds.ceremonyHasVoted[_code][msg.sender]) revert AlreadyVoted();
        if (block.timestamp < ds.vestingStart[msg.sender] + ds.vestingPeriod) revert NFTNotVested();

        ds.ceremonyVotes[_code][msg.sender] = _voteValue;
        ds.ceremonyHasVoted[_code][msg.sender] = true;
        
        // Atualiza o contador de votos no badge do usuário
        uint256 tokenId = ds.userToken[msg.sender];
        if (tokenId != 0) {
            ds.badgeData[tokenId].votesCast++;
        }
        
        emit VoteCast(_code, msg.sender, _voteValue);
    }

    /**
     * @notice Abre uma nova sessão de votação para uma funcionalidade específica.
     * @param _code Código único da cerimônia.
     * @param _functionalityCode Código da funcionalidade a ser votada.
     * Requisito: Apenas o Scrum Master pode abrir sessões.
     */
    function openFunctionalityVote(string memory _code, string memory _functionalityCode) 
        external 
        whenNotPaused 
    {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        if (!ds.ceremonyExists[_code]) revert CeremonyNotFound();
        if (msg.sender != ds.ceremonies[_code].scrumMaster && !_hasRole(ScrumPokerStorage.ADMIN_ROLE, msg.sender)) {
            revert NotAuthorized();
        }
        if (!ds.ceremonies[_code].active) revert CeremonyNotActive();

        uint256 sessionIndex = ds.functionalityVoteSessions[_code].length;
        ScrumPokerStorage.FunctionalityVoteSession storage session = ds.functionalityVoteSessions[_code].push();
        session.functionalityCode = _functionalityCode;
        session.active = true;

        emit FunctionalityVoteOpened(_code, _functionalityCode, sessionIndex);
    }

    /**
     * @notice Permite que um participante vote em uma sessão de votação de funcionalidade.
     * @param _code Código único da cerimônia.
     * @param _sessionIndex Índice da sessão.
     * @param _voteValue Valor do voto para a funcionalidade.
     * Requisitos:
     * - A cerimônia deve estar ativa.
     * - O participante deve estar aprovado.
     * - Não pode ter votado nesta sessão.
     * - O NFT deve estar "vested".
     */
    function voteFunctionality(string memory _code, uint256 _sessionIndex, uint256 _voteValue) 
        external 
        whenNotPaused 
    {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        if (!ds.ceremonyExists[_code]) revert CeremonyNotFound();
        if (!ds.ceremonies[_code].active) revert CeremonyNotActive();
        if (!ds.ceremonyApproved[_code][msg.sender]) revert ParticipantNotApproved();
        if (_sessionIndex >= ds.functionalityVoteSessions[_code].length) revert SessionNotFound();

        ScrumPokerStorage.FunctionalityVoteSession storage session = ds.functionalityVoteSessions[_code][_sessionIndex];
        if (!session.active) revert SessionNotActive();
        if (session.hasVoted[msg.sender]) revert AlreadyVoted();
        if (block.timestamp < ds.vestingStart[msg.sender] + ds.vestingPeriod) revert NFTNotVested();

        session.votes[msg.sender] = _voteValue;
        session.hasVoted[msg.sender] = true;
        
        emit FunctionalityVoteCast(_code, _sessionIndex, msg.sender, _voteValue);
    }

    /**
     * @notice Encerra uma sessão de votação de funcionalidade.
     * @param _code Código único da cerimônia.
     * @param _sessionIndex Índice da sessão.
     * Requisito: Apenas o Scrum Master pode encerrar a sessão.
     */
    function closeFunctionalityVote(string memory _code, uint256 _sessionIndex) 
        external 
        whenNotPaused 
    {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        if (!ds.ceremonyExists[_code]) revert CeremonyNotFound();
        if (msg.sender != ds.ceremonies[_code].scrumMaster && !_hasRole(ScrumPokerStorage.ADMIN_ROLE, msg.sender)) {
            revert NotAuthorized();
        }
        if (_sessionIndex >= ds.functionalityVoteSessions[_code].length) revert SessionNotFound();

        ScrumPokerStorage.FunctionalityVoteSession storage session = ds.functionalityVoteSessions[_code][_sessionIndex];
        if (!session.active) revert SessionNotActive();

        session.active = false;
    }

    /**
     * @notice Atualiza os badges NFT dos participantes com os resultados da cerimônia.
     * @param _code Código único da cerimônia.
     * Requisito: A cerimônia deve estar concluída.
     */
    function updateBadges(string memory _code) external whenNotPaused nonReentrant {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        if (!ds.ceremonyExists[_code]) revert CeremonyNotFound();
        ScrumPokerStorage.Ceremony storage ceremony = ds.ceremonies[_code];
        if (ceremony.active) revert CeremonyNotActive();
        if (msg.sender != ceremony.scrumMaster && !_hasRole(ScrumPokerStorage.ADMIN_ROLE, msg.sender)) {
            revert NotAuthorized();
        }

        for (uint256 i = 0; i < ceremony.participants.length; i++) {
            address participant = ceremony.participants[i];
            uint256 tokenId = ds.userToken[participant];
            if (tokenId == 0) continue;

            uint256 totalPoints = 0;
            if (ds.ceremonyHasVoted[_code][participant]) {
                totalPoints += ds.ceremonyVotes[_code][participant];
            }

            // Arrays temporários para votos de funcionalidades
            string[] memory funcCodesTemp = new string[](ds.functionalityVoteSessions[_code].length);
            uint256[] memory funcVotesTemp = new uint256[](ds.functionalityVoteSessions[_code].length);
            uint256 validSessionCount = 0;

            // Coleta os votos de funcionalidades
            for (uint256 j = 0; j < ds.functionalityVoteSessions[_code].length; j++) {
                ScrumPokerStorage.FunctionalityVoteSession storage session = ds.functionalityVoteSessions[_code][j];
                if (session.hasVoted[participant]) {
                    funcCodesTemp[validSessionCount] = session.functionalityCode;
                    funcVotesTemp[validSessionCount] = session.votes[participant];
                    totalPoints += session.votes[participant];
                    validSessionCount++;
                }
            }

            // Cria arrays de tamanho correto com os dados válidos
            string[] memory functionalityCodes = new string[](validSessionCount);
            uint256[] memory functionalityVotes = new uint256[](validSessionCount);
            for (uint256 j = 0; j < validSessionCount; j++) {
                functionalityCodes[j] = funcCodesTemp[j];
                functionalityVotes[j] = funcVotesTemp[j];
            }

            // Cria um novo SprintResult e adiciona ao histórico do badge
            ScrumPokerStorage.SprintResult memory result = ScrumPokerStorage.SprintResult({
                sprintNumber: ceremony.sprintNumber,
                startTime: ceremony.startTime,
                endTime: ceremony.endTime,
                totalPoints: totalPoints,
                functionalityCodes: functionalityCodes,
                functionalityVotes: functionalityVotes
            });

            ds.badgeData[tokenId].sprintResults.push(result);
            ds.badgeData[tokenId].ceremoniesParticipated++;

            emit NFTBadgeUpdated(participant, tokenId, ceremony.sprintNumber);
        }
    }

    /**
     * @notice Verifica se um participante votou em uma cerimônia.
     * @param _code Código da cerimônia.
     * @param _participant Endereço do participante.
     * @return bool Verdadeiro se o participante votou.
     */
    function hasVoted(string memory _code, address _participant) external view returns (bool) {
        return ScrumPokerStorage.diamondStorage().ceremonyHasVoted[_code][_participant];
    }

    /**
     * @notice Obtém o voto de um participante em uma cerimônia.
     * @param _code Código da cerimônia.
     * @param _participant Endereço do participante.
     * @return uint256 Valor do voto.
     */
    function getVote(string memory _code, address _participant) external view returns (uint256) {
        return ScrumPokerStorage.diamondStorage().ceremonyVotes[_code][_participant];
    }

    /**
     * @notice Verifica se um participante votou em uma sessão de funcionalidade.
     * @param _code Código da cerimônia.
     * @param _sessionIndex Índice da sessão.
     * @param _participant Endereço do participante.
     * @return bool Verdadeiro se o participante votou.
     */
    function hasFunctionalityVoted(string memory _code, uint256 _sessionIndex, address _participant) 
        external 
        view 
        returns (bool) 
    {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        if (!ds.ceremonyExists[_code] || _sessionIndex >= ds.functionalityVoteSessions[_code].length) {
            return false;
        }
        return ds.functionalityVoteSessions[_code][_sessionIndex].hasVoted[_participant];
    }

    /**
     * @notice Obtém o voto de um participante em uma sessão de funcionalidade.
     * @param _code Código da cerimônia.
     * @param _sessionIndex Índice da sessão.
     * @param _participant Endereço do participante.
     * @return uint256 Valor do voto.
     */
    function getFunctionalityVote(string memory _code, uint256 _sessionIndex, address _participant) 
        external 
        view 
        returns (uint256) 
    {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        if (!ds.ceremonyExists[_code] || _sessionIndex >= ds.functionalityVoteSessions[_code].length) {
            return 0;
        }
        return ds.functionalityVoteSessions[_code][_sessionIndex].votes[_participant];
    }

    /**
     * @dev Verifica se um endereço tem um papel específico.
     * @param role O papel a ser verificado.
     * @param account O endereço a ser verificado.
     * @return bool Verdadeiro se o endereço tiver o papel.
     */
    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return ScrumPokerStorage.diamondStorage().roles[role][account];
    }
}