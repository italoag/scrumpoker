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
     * @dev Inicializa o contrato VotingFacet e verifica/inicializa o versionamento do storage.
     */
    function initializeVoting() external initializer {
        __ReentrancyGuard_init();
        
        // Inicializa ou verifica o storage versionado
        ScrumPokerStorage.initializeStorage();
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
        // Verifica se o storage está inicializado e na versão correta
        ScrumPokerStorage.requireCorrectStorageVersion();
        
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Verifica se a cerimônia existe usando o helper
        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        
        // Obtem a cerimônia usando o helper
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        if (!ceremony.active) revert CeremonyNotActive();
        
        // Obtem o hash otimizado para usar nas verificações
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHash(_code);
        
        // Verifica se o participante está aprovado (em ambos os formatos)
        if (!ds.ceremonyApproved[codeHash][msg.sender] && !ds._deprecatedCeremonyApproved[_code][msg.sender]) revert ParticipantNotApproved();
        
        // Verifica se já votou (em ambos os formatos)
        if (ds.ceremonyHasVoted[codeHash][msg.sender] || ds._deprecatedCeremonyHasVoted[_code][msg.sender]) revert AlreadyVoted();
        
        // Verifica o período de vesting
        if (block.timestamp < ds.vestingStart[msg.sender] + ds.vestingPeriod) revert NFTNotVested();

        // Registra o voto no formato otimizado
        ds.ceremonyVotes[codeHash][msg.sender] = _voteValue;
        ds.ceremonyHasVoted[codeHash][msg.sender] = true;
        
        // Mantém compatibilidade com o formato legado
        ds._deprecatedCeremonyVotes[_code][msg.sender] = _voteValue;
        ds._deprecatedCeremonyHasVoted[_code][msg.sender] = true;
        
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
        // Verifica se o storage está na versão correta
        ScrumPokerStorage.requireCorrectStorageVersion();
        
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Verifica se a cerimônia existe usando o helper
        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        
        // Obtém a cerimônia usando o helper
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        
        // Verifica autorização
        if (msg.sender != ceremony.scrumMaster && !_hasRole(ScrumPokerStorage.ADMIN_ROLE, msg.sender)) {
            revert NotAuthorized();
        }
        
        // Verifica se está ativa
        if (!ceremony.active) revert CeremonyNotActive();

        // Obtém o hash do código para armazenamento otimizado
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHash(_code);
        
        // Cria uma nova sessão no formato otimizado
        uint256 sessionIndex = ds.functionalityVoteSessions[codeHash].length;
        ds.functionalityVoteSessions[codeHash].push();
        ScrumPokerStorage.FunctionalityVoteSession storage session = ds.functionalityVoteSessions[codeHash][sessionIndex];
        
        // Configura os campos da sessão, incluindo o hash do código da funcionalidade
        bytes32 functionalityHash = ScrumPokerStorage.stringToBytes32(_functionalityCode);
        session.functionalityCodeHash = functionalityHash;
        session.functionalityCode = _functionalityCode;
        session.active = true;

        // Mantém compatibilidade com o formato legado
        ds._deprecatedFunctionalitySessions[_code].push();
        ScrumPokerStorage.FunctionalityVoteSession storage legacySession = ds._deprecatedFunctionalitySessions[_code][sessionIndex];
        legacySession.functionalityCode = _functionalityCode;
        legacySession.active = true;

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
        // Verifica se o storage está na versão correta
        ScrumPokerStorage.requireCorrectStorageVersion();
        
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Verifica se a cerimônia existe usando o helper
        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        
        // Obtém a cerimônia usando o helper
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        if (!ceremony.active) revert CeremonyNotActive();
        
        // Obtém o hash do código para uso no formato otimizado
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHash(_code);
        
        // Verifica se o participante está aprovado (em ambos os formatos)
        if (!ds.ceremonyApproved[codeHash][msg.sender] && !ds._deprecatedCeremonyApproved[_code][msg.sender]) 
            revert ParticipantNotApproved();
        
        // Verifica se a sessão existe no formato otimizado
        if (_sessionIndex >= ds.functionalityVoteSessions[codeHash].length) {
            // Tenta verificar no formato legado se não encontrar no otimizado
            if (_sessionIndex >= ds._deprecatedFunctionalitySessions[_code].length) 
                revert SessionNotFound();
            
            // Se encontrado no formato legado, migra para o otimizado
            if (ds.functionalityVoteSessions[codeHash].length == 0) {
                for (uint256 i = 0; i < ds._deprecatedFunctionalitySessions[_code].length; i++) {
                    ScrumPokerStorage.FunctionalityVoteSession storage legacySession = ds._deprecatedFunctionalitySessions[_code][i];
                    
                    // Usar .push() sem argumentos e depois definir valores para evitar problemas com mappings aninhados
                    ds.functionalityVoteSessions[codeHash].push();
                    ScrumPokerStorage.FunctionalityVoteSession storage newSession = ds.functionalityVoteSessions[codeHash][i];
                    
                    bytes32 functionalityHash = ScrumPokerStorage.stringToBytes32(legacySession.functionalityCode);
                    newSession.functionalityCodeHash = functionalityHash;
                    newSession.functionalityCode = legacySession.functionalityCode;
                    newSession.active = legacySession.active;
                }
            }
        }

        // Agora que garantimos que a sessão existe no formato otimizado, obtemos ela
        ScrumPokerStorage.FunctionalityVoteSession storage session = ds.functionalityVoteSessions[codeHash][_sessionIndex];
        
        // Verifica se a sessão está ativa
        if (!session.active) revert SessionNotActive();
        if (session.hasVoted[msg.sender]) revert AlreadyVoted();
        if (block.timestamp < ds.vestingStart[msg.sender] + ds.vestingPeriod) revert NFTNotVested();

        // Registra o voto no formato otimizado
        session.votes[msg.sender] = _voteValue;
        session.hasVoted[msg.sender] = true;
        
        // Mantém compatibilidade com o formato legado
        if (_sessionIndex < ds._deprecatedFunctionalitySessions[_code].length) {
            ds._deprecatedFunctionalitySessions[_code][_sessionIndex].votes[msg.sender] = _voteValue;
            ds._deprecatedFunctionalitySessions[_code][_sessionIndex].hasVoted[msg.sender] = true;
        }
        
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
        // Verifica se o storage está na versão correta
        ScrumPokerStorage.requireCorrectStorageVersion();
        
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Verifica se a cerimônia existe usando o helper
        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        
        // Obtém a cerimônia usando o helper
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        
        // Verifica autorização
        if (msg.sender != ceremony.scrumMaster && !_hasRole(ScrumPokerStorage.ADMIN_ROLE, msg.sender)) {
            revert NotAuthorized();
        }
        
        // Obtém o hash do código para uso no formato otimizado
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHash(_code);
        
        // Verificar em ambos os formatos se a sessão existe
        bool sessionExists = false;
        
        // Verifica no formato otimizado
        if (_sessionIndex < ds.functionalityVoteSessions[codeHash].length) {
            ScrumPokerStorage.FunctionalityVoteSession storage session = ds.functionalityVoteSessions[codeHash][_sessionIndex];
            if (!session.active) revert SessionNotActive();
            
            // Desativa no formato otimizado
            session.active = false;
            sessionExists = true;
        }
        
        // Verifica também no formato legado
        if (_sessionIndex < ds._deprecatedFunctionalitySessions[_code].length) {
            ScrumPokerStorage.FunctionalityVoteSession storage legacySession = ds._deprecatedFunctionalitySessions[_code][_sessionIndex];
            
            // Desativa no formato legado
            legacySession.active = false;
            sessionExists = true;
        }
        
        // Se não encontrou a sessão em nenhum formato, reverte
        if (!sessionExists) revert SessionNotFound();
    }

    /**
     * @notice Atualiza os badges NFT dos participantes com os resultados da cerimônia.
     * @param _code Código único da cerimônia.
     * Requisito: A cerimônia deve estar concluída.
     */
    function updateBadges(string memory _code) external whenNotPaused nonReentrant {
        // Verifica se o storage está na versão correta
        ScrumPokerStorage.requireCorrectStorageVersion();
        
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Verifica se a cerimônia existe usando o helper
        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        
        // Obtém a cerimônia usando o helper
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        if (ceremony.active) revert CeremonyNotActive();
        if (msg.sender != ceremony.scrumMaster && !_hasRole(ScrumPokerStorage.ADMIN_ROLE, msg.sender)) {
            revert NotAuthorized();
        }
        
        // Obtém o hash do código para uso no formato otimizado
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHash(_code);

        for (uint256 i = 0; i < ceremony.participants.length; i++) {
            address participant = ceremony.participants[i];
            uint256 tokenId = ds.userToken[participant];
            if (tokenId == 0) continue;

            uint256 totalPoints = 0;
            
            // Verifica votos em ambos os formatos (otimizado e legado)
            if (ds.ceremonyHasVoted[codeHash][participant] || ds._deprecatedCeremonyHasVoted[_code][participant]) {
                // Preferir o formato otimizado se disponível
                if (ds.ceremonyHasVoted[codeHash][participant]) {
                    totalPoints += ds.ceremonyVotes[codeHash][participant];
                } else {
                    totalPoints += ds._deprecatedCeremonyVotes[_code][participant];
                }
            }

            // Determina o número de sessões no formato otimizado e legado
            uint256 sessionCount = ds.functionalityVoteSessions[codeHash].length;
            if (ds._deprecatedFunctionalitySessions[_code].length > sessionCount) {
                sessionCount = ds._deprecatedFunctionalitySessions[_code].length;
            }
            
            // Arrays temporários para votos de funcionalidades
            string[] memory funcCodesTemp = new string[](sessionCount);
            uint256[] memory funcVotesTemp = new uint256[](sessionCount);
            uint256 validSessionCount = 0;

            // Coleta os votos de funcionalidades - primeiro no formato otimizado
            for (uint256 j = 0; j < ds.functionalityVoteSessions[codeHash].length; j++) {
                ScrumPokerStorage.FunctionalityVoteSession storage session = ds.functionalityVoteSessions[codeHash][j];
                if (session.hasVoted[participant]) {
                    funcCodesTemp[validSessionCount] = session.functionalityCode;
                    funcVotesTemp[validSessionCount] = session.votes[participant];
                    totalPoints += session.votes[participant];
                    validSessionCount++;
                }
            }
            
            // Coleta qualquer voto adicional do formato legado que não foi migrado
            for (uint256 j = 0; j < ds._deprecatedFunctionalitySessions[_code].length; j++) {
                ScrumPokerStorage.FunctionalityVoteSession storage session = ds._deprecatedFunctionalitySessions[_code][j];
                if (session.hasVoted[participant]) {
                    // Verifica se este voto já foi contabilizado no formato otimizado
                    bool alreadyCounted = false;
                    for (uint256 k = 0; k < validSessionCount; k++) {
                        if (keccak256(abi.encodePacked(funcCodesTemp[k])) == keccak256(abi.encodePacked(session.functionalityCode))) {
                            alreadyCounted = true;
                            break;
                        }
                    }
                    
                    // Se não foi contabilizado, adiciona aos resultados
                    if (!alreadyCounted) {
                        funcCodesTemp[validSessionCount] = session.functionalityCode;
                        funcVotesTemp[validSessionCount] = session.votes[participant];
                        totalPoints += session.votes[participant];
                        validSessionCount++;
                    }
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
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Verifica em ambos os formatos (otimizado e legado)
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHashView(_code);
        return ds.ceremonyHasVoted[codeHash][_participant] || ds._deprecatedCeremonyHasVoted[_code][_participant];
    }

    /**
     * @notice Obtém o voto de um participante em uma cerimônia.
     * @param _code Código da cerimônia.
     * @param _participant Endereço do participante.
     * @return uint256 Valor do voto.
     */
    function getVote(string memory _code, address _participant) external view returns (uint256) {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Verifica em ambos os formatos (otimizado e legado)
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHashView(_code);
        
        // Prioriza o formato otimizado se o voto estiver lá
        if (ds.ceremonyHasVoted[codeHash][_participant]) {
            return ds.ceremonyVotes[codeHash][_participant];
        }
        
        // Caso contrário, retorna do formato legado
        return ds._deprecatedCeremonyVotes[_code][_participant];
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
        
        // Verifica em ambos os formatos (otimizado e legado)
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHashView(_code);
        
        // Verifica no formato otimizado
        if (_sessionIndex < ds.functionalityVoteSessions[codeHash].length) {
            if (ds.functionalityVoteSessions[codeHash][_sessionIndex].hasVoted[_participant]) {
                return true;
            }
        }
        
        // Caso não esteja no formato otimizado, verifica no legado
        if (!ScrumPokerStorage.ceremonyExists(_code) || _sessionIndex >= ds._deprecatedFunctionalitySessions[_code].length) {
            return false;
        }
        return ds._deprecatedFunctionalitySessions[_code][_sessionIndex].hasVoted[_participant];
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
        
        // Verifica em ambos os formatos (otimizado e legado)
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHashView(_code);
        
        // Verifica no formato otimizado
        if (_sessionIndex < ds.functionalityVoteSessions[codeHash].length &&
            ds.functionalityVoteSessions[codeHash][_sessionIndex].hasVoted[_participant]) {
            return ds.functionalityVoteSessions[codeHash][_sessionIndex].votes[_participant];
        }
        
        // Caso não esteja no formato otimizado, verifica no legado
        if (!ScrumPokerStorage.ceremonyExists(_code) || _sessionIndex >= ds._deprecatedFunctionalitySessions[_code].length) {
            return 0;
        }
        return ds._deprecatedFunctionalitySessions[_code][_sessionIndex].votes[_participant];
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