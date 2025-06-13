// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../ScrumPokerStorage.sol";
import "../library/StringUtils.sol";
import "../library/ValidationUtils.sol";

/// @title VotingFacet – optimized voting logic with no legacy storage
/// @notice Handles general votes, functionality vote sessions and NFT badge updates using only the
///         optimized storage layout (codeHash-based mappings) defined in `ScrumPokerStorage`.
/// @dev This file entirely replaces the previous `VotingFacetLegacy.sol`, which mixed legacy + optimized
///      storage. All `_deprecated*` references were removed.
contract VotingFacet is Initializable, ReentrancyGuardUpgradeable {
    using StringUtils for string;
    using ValidationUtils for address;
    using ValidationUtils for uint256;

    /*─────────────────────────── Events ───────────────────────────*/
    event VoteCast(string ceremonyCode, address indexed participant, uint256 voteValue);
    event FunctionalityVoteOpened(string ceremonyCode, string functionalityCode, uint256 sessionIndex);
    event FunctionalityVoteCast(string ceremonyCode, uint256 sessionIndex, address indexed participant, uint256 voteValue);
    event FunctionalityVoteClosed(string ceremonyCode, uint256 sessionIndex, address indexed closer);
    event NFTBadgeUpdated(address indexed participant, uint256 tokenId, uint256 sprintNumber);
    event BadgeBatchProcessed(string ceremonyCode, uint256 startIndex, uint256 endIndex);

    /*─────────────────────────── Errors ───────────────────────────*/
    error CeremonyNotFound();
    error CeremonyNotActive();
    error NotAuthorized();
    error ParticipantNotApproved();
    error AlreadyVoted();
    error NFTNotVested();
    error SessionNotFound();
    error SessionNotActive();
    error DuplicateFunctionalitySession();
    error InvalidRange();
    error InvalidVoteValue();

    /*─────────────────────────── Constants ────────────────────────*/
    uint256 public constant MAX_VOTE_VALUE = 100;

    /*─────────────────────────── Modifiers ────────────────────────*/
    modifier whenNotPaused() {
        require(!ScrumPokerStorage.diamondStorage().paused, "VotingFacet: paused");
        _;
    }

    /*──────────────────────── Initializer ────────────────────────*/
    function initializeVoting() external initializer {
        __ReentrancyGuard_init();
        ScrumPokerStorage.initializeStorage();
    }

    /*────────────────────────── General Vote ─────────────────────*/
    function vote(string memory _code, uint256 _voteValue) external whenNotPaused {
        ScrumPokerStorage.requireCorrectStorageVersion();
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();

        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        if (!ceremony.active) revert CeremonyNotActive();

        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHash(_code);
        if (!ds.ceremonyApproved[codeHash][msg.sender]) revert ParticipantNotApproved();
        if (ds.ceremonyHasVoted[codeHash][msg.sender]) revert AlreadyVoted();
        if (_voteValue > MAX_VOTE_VALUE) revert InvalidVoteValue();
        if (block.timestamp < ds.vestingStart[msg.sender] + ds.vestingPeriod) revert NFTNotVested();

        ds.ceremonyVotes[codeHash][msg.sender] = _voteValue;
        ds.ceremonyHasVoted[codeHash][msg.sender] = true;

        uint256 tokenId = ds.userToken[msg.sender];
        if (tokenId != 0) ds.badgeData[tokenId].votesCast++;

        emit VoteCast(_code, msg.sender, _voteValue);
    }

    /*────────────────── Functionality Vote Sessions ──────────────*/
    function openFunctionalityVote(string memory _code, string memory _functionality)
        external
        whenNotPaused
    {
        ScrumPokerStorage.requireCorrectStorageVersion();
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();

        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        if (msg.sender != ceremony.scrumMaster && !_hasRole(ScrumPokerStorage.ADMIN_ROLE, msg.sender)) {
            revert NotAuthorized();
        }
        if (!ceremony.active) revert CeremonyNotActive();

        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHash(_code);
        bytes32 funcHash = _functionality.stringToBytes32();

        // duplicate check
        uint256 sessionsLen = ds.functionalityVoteSessions[codeHash].length;
        for (uint256 i; i < sessionsLen; i++) {
            if (ds.functionalityVoteSessions[codeHash][i].functionalityCodeHash == funcHash) {
                revert DuplicateFunctionalitySession();
            }
        }

        uint256 newIdx = sessionsLen;
        ds.functionalityVoteSessions[codeHash].push();
        ScrumPokerStorage.FunctionalityVoteSession storage s = ds.functionalityVoteSessions[codeHash][newIdx];
        s.functionalityCodeHash = funcHash;
        s.functionalityCode = _functionality;
        s.active = true;

        emit FunctionalityVoteOpened(_code, _functionality, newIdx);
    }

    function voteFunctionality(string memory _code, uint256 _sessionIdx, uint256 _voteValue)
        external
        whenNotPaused
    {
        ScrumPokerStorage.requireCorrectStorageVersion();
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();

        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        if (!ceremony.active) revert CeremonyNotActive();

        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHash(_code);
        if (!ds.ceremonyApproved[codeHash][msg.sender]) revert ParticipantNotApproved();
        if (_sessionIdx >= ds.functionalityVoteSessions[codeHash].length) revert SessionNotFound();

        ScrumPokerStorage.FunctionalityVoteSession storage s = ds.functionalityVoteSessions[codeHash][_sessionIdx];
        if (!s.active) revert SessionNotActive();
        if (s.hasVoted[msg.sender]) revert AlreadyVoted();
        if (_voteValue > MAX_VOTE_VALUE) revert InvalidVoteValue();
        if (block.timestamp < ds.vestingStart[msg.sender] + ds.vestingPeriod) revert NFTNotVested();

        s.votes[msg.sender] = _voteValue;
        s.hasVoted[msg.sender] = true;

        emit FunctionalityVoteCast(_code, _sessionIdx, msg.sender, _voteValue);
    }

    function closeFunctionalityVote(string memory _code, uint256 _sessionIdx)
        external
        whenNotPaused
    {
        ScrumPokerStorage.requireCorrectStorageVersion();
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();

        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        if (msg.sender != ceremony.scrumMaster && !_hasRole(ScrumPokerStorage.ADMIN_ROLE, msg.sender)) revert NotAuthorized();

        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHash(_code);
        if (_sessionIdx >= ds.functionalityVoteSessions[codeHash].length) revert SessionNotFound();

        ScrumPokerStorage.FunctionalityVoteSession storage s = ds.functionalityVoteSessions[codeHash][_sessionIdx];
        if (!s.active) revert SessionNotActive();

        s.active = false;
        emit FunctionalityVoteClosed(_code, _sessionIdx, msg.sender);
    }

    /*──────────────────── Badge Update (batched) ─────────────────*/
    function updateBadgesRange(string memory _code, uint256 start, uint256 end)
        external
        nonReentrant
        whenNotPaused
    {
        if (end <= start) revert InvalidRange();
        ScrumPokerStorage.requireCorrectStorageVersion();
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();

        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        if (ceremony.active) revert CeremonyNotActive(); // must be finished
        if (msg.sender != ceremony.scrumMaster && !_hasRole(ScrumPokerStorage.ADMIN_ROLE, msg.sender)) revert NotAuthorized();

        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHash(_code);

        for (uint256 i = start; i < end && i < ceremony.participants.length; i++) {
            address participant = ceremony.participants[i];
            uint256 tokenId = ds.userToken[participant];
            if (tokenId == 0) continue;

            uint256 totalPoints = ds.ceremonyVotes[codeHash][participant];

            uint256 sessionsLen = ds.functionalityVoteSessions[codeHash].length;
            string[] memory codes = new string[](sessionsLen);
            uint256[] memory votes = new uint256[](sessionsLen);
            uint256 validCount;
            for (uint256 j; j < sessionsLen; j++) {
                ScrumPokerStorage.FunctionalityVoteSession storage s = ds.functionalityVoteSessions[codeHash][j];
                if (s.hasVoted[participant]) {
                    codes[validCount] = s.functionalityCode;
                    votes[validCount] = s.votes[participant];
                    totalPoints += s.votes[participant];
                    validCount++;
                }
            }
            // shrink arrays to validCount
            string[] memory finalCodes = new string[](validCount);
            uint256[] memory finalVotes = new uint256[](validCount);
            for (uint256 k; k < validCount; k++) {
                finalCodes[k] = codes[k];
                finalVotes[k] = votes[k];
            }

            ScrumPokerStorage.SprintResult memory result = ScrumPokerStorage.SprintResult({
                sprintNumber: ceremony.sprintNumber,
                startTime: ceremony.startTime,
                endTime: ceremony.endTime,
                totalPoints: totalPoints,
                functionalityCodes: finalCodes,
                functionalityVotes: finalVotes
            });
            ds.badgeData[tokenId].sprintResults.push(result);
            ds.badgeData[tokenId].ceremoniesParticipated++;
            emit NFTBadgeUpdated(participant, tokenId, ceremony.sprintNumber);
        }

        emit BadgeBatchProcessed(_code, start, end);
    }

    /*────────────────────── Getters (view) ───────────────────────*/
    function hasVoted(string memory _code, address _participant) external view returns (bool) {
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHashView(_code);
        return ScrumPokerStorage.diamondStorage().ceremonyHasVoted[codeHash][_participant];
    }

    function getVote(string memory _code, address _participant) external view returns (uint256) {
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHashView(_code);
        return ScrumPokerStorage.diamondStorage().ceremonyVotes[codeHash][_participant];
    }

    function hasFunctionalityVoted(string memory _code, uint256 _sessionIdx, address _participant)
        external
        view
        returns (bool)
    {
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHashView(_code);
        if (_sessionIdx >= ScrumPokerStorage.diamondStorage().functionalityVoteSessions[codeHash].length) return false;
        return ScrumPokerStorage.diamondStorage().functionalityVoteSessions[codeHash][_sessionIdx].hasVoted[_participant];
    }

    function getFunctionalityVote(string memory _code, uint256 _sessionIdx, address _participant)
         external
         view
         returns (uint256)
    {
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHashView(_code);
        if (_sessionIdx >= ScrumPokerStorage.diamondStorage().functionalityVoteSessions[codeHash].length) return 0;
        return ScrumPokerStorage.diamondStorage().functionalityVoteSessions[codeHash][_sessionIdx].votes[_participant];
    }

    /**
     * @notice Retorna o total de pontos (voto da cerimônia + votos de funcionalidades) de um participante.
     */
    function getParticipantTotalPoints(string memory _code, address _participant) public view returns (uint256 total) {
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHashView(_code);
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        total = ds.ceremonyVotes[codeHash][_participant];
        uint256 sessionsLen = ds.functionalityVoteSessions[codeHash].length;
        for (uint256 i; i < sessionsLen; i++) {
            ScrumPokerStorage.FunctionalityVoteSession storage s = ds.functionalityVoteSessions[codeHash][i];
            if (s.hasVoted[_participant]) {
                total += s.votes[_participant];
            }
        }
    }

    /**
     * @notice Obtém resultados consolidados da cerimônia (todos os participantes e seus totais de pontos).
     * @return participants Lista de participantes.
     * @return totals Pontuação total correspondente.
     */
    function getCeremonyResults(string memory _code)
        external
        view
        returns (address[] memory participants, uint256[] memory totals)
    {
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        uint256 len = ceremony.participants.length;
        participants = new address[](len);
        totals = new uint256[](len);
        for (uint256 i; i < len; i++) {
            address p = ceremony.participants[i];
            participants[i] = p;
            totals[i] = getParticipantTotalPoints(_code, p);
        }
    }

    /**
     * @notice Obtém o resultado consolidado de voto de funcionalidade.
     * @dev Reverte se a sessão não existir.
     * @return voters Lista de quem votou.
     * @return votes_ Valor do voto para cada participante.
     */
    function getFunctionalityResults(string memory _code, uint256 _sessionIdx)
        external
        view
        returns (address[] memory voters, uint256[] memory votes_)
    {
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHashView(_code);
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        if (_sessionIdx >= ds.functionalityVoteSessions[codeHash].length) revert SessionNotFound();
        ScrumPokerStorage.FunctionalityVoteSession storage s = ds.functionalityVoteSessions[codeHash][_sessionIdx];

        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        uint256 len = ceremony.participants.length;
        uint256 count;
        for (uint256 i; i < len; i++) {
            if (s.hasVoted[ceremony.participants[i]]) {
                count++;
            }
        }
        voters = new address[](count);
        votes_ = new uint256[](count);
        uint256 idx;
        for (uint256 i; i < len; i++) {
            address p = ceremony.participants[i];
            if (s.hasVoted[p]) {
                voters[idx] = p;
                votes_[idx] = s.votes[p];
                idx++;
            }
        }
    }

    /*──────────────────────── Internal helpers ───────────────────*/
    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return ScrumPokerStorage.diamondStorage().roles[role][account];
    }
}
