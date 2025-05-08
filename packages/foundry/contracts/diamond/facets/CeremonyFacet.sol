// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../ScrumPokerStorage.sol";

/**
 * @title CeremonyFacet
 * @dev Faceta para gerenciar as cerimônias (sprints) do ScrumPoker.
 * Implementa a criação de cerimônias, solicitação de entrada e aprovação de participantes.
 */
contract CeremonyFacet is Initializable, ReentrancyGuardUpgradeable {
    // Eventos
    event CeremonyStarted(string ceremonyCode, uint256 sprintNumber, uint256 startTime, address indexed scrumMaster);
    event CeremonyEntryRequested(string ceremonyCode, address indexed participant);
    event EntryApproved(string ceremonyCode, address indexed participant);
    event CeremonyConcluded(string ceremonyCode, uint256 endTime, uint256 sprintNumber);

    // Erros
    error CeremonyNotFound();
    error NotAuthorized();
    error EntryAlreadyRequested();
    error EntryNotRequested();
    error ParticipantAlreadyApproved();
    error NFTRequired();
    error CeremonyNotActive();
    event CeremonyCreated(string ceremonyCode, uint256 sprintNumber);

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
        require(!ScrumPokerStorage.diamondStorage().paused, "CeremonyFacet: pausado");
        _;
    }

    /**
     * @dev Inicializa o contrato CeremonyFacet.
     */
    function initializeCeremony() external initializer {
        __ReentrancyGuard_init();
    }

    /**
     * @notice Inicia uma nova cerimônia (sprint), gerando um código único.
     * @param _sprintNumber Número do sprint associado à cerimônia.
     * @return code Código único gerado para a cerimônia.
     */
    function startCeremony(uint256 _sprintNumber) 
        external 
        whenNotPaused 
        returns (string memory) 
    {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Gera um código único para a cerimônia
        string memory code = string(abi.encodePacked("CEREMONY", uint2str(ds.ceremonyCounter)));
        ds.ceremonyCounter++;

        // Inicializa a estrutura da cerimônia
        ScrumPokerStorage.Ceremony storage ceremony = ds.ceremonies[code];
        ceremony.code = code;
        ceremony.sprintNumber = _sprintNumber;
        ceremony.startTime = block.timestamp;
        ceremony.scrumMaster = msg.sender;
        ceremony.active = true;

        ds.ceremonyExists[code] = true;
        
        // Concede automaticamente o papel de Scrum Master ao criador da cerimônia
        if (!_hasRole(ScrumPokerStorage.SCRUM_MASTER_ROLE, msg.sender)) {
            _grantRole(ScrumPokerStorage.SCRUM_MASTER_ROLE, msg.sender);
        }
        
        emit CeremonyStarted(code, _sprintNumber, ceremony.startTime, msg.sender);
        return code;
    }

    /**
     * @notice Permite que um usuário solicite participação em uma cerimônia.
     * @param _code Código único da cerimônia.
     * Requisito: o usuário deve possuir um NFT.
     */
    function requestCeremonyEntry(string memory _code) external whenNotPaused {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        if (!ds.ceremonyExists[_code]) revert CeremonyNotFound();
        if (ds.userToken[msg.sender] == 0) revert NFTRequired();
        if (ds.hasRequestedEntry[_code][msg.sender]) revert EntryAlreadyRequested();

        ds.hasRequestedEntry[_code][msg.sender] = true;
        emit CeremonyEntryRequested(_code, msg.sender);
    }

    /**
     * @notice Aprova a entrada de um participante na cerimônia.
     * @param _code Código único da cerimônia.
     * @param _participant Endereço do participante.
     * Apenas o Scrum Master pode aprovar; ao aprovar, o vesting do participante é reiniciado.
     */
    function approveEntry(string memory _code, address _participant) external whenNotPaused {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        if (!ds.ceremonyExists[_code]) revert CeremonyNotFound();
        if (msg.sender != ds.ceremonies[_code].scrumMaster && !_hasRole(ScrumPokerStorage.ADMIN_ROLE, msg.sender)) {
            revert NotAuthorized();
        }
        if (!ds.hasRequestedEntry[_code][_participant]) revert EntryNotRequested();
        if (ds.ceremonyApproved[_code][_participant]) revert ParticipantAlreadyApproved();

        ds.ceremonyApproved[_code][_participant] = true;
        ds.ceremonies[_code].participants.push(_participant);
        ds.vestingStart[_participant] = block.timestamp;
        emit EntryApproved(_code, _participant);
    }

    /**
     * @notice Conclui a cerimônia.
     * @param _code Código único da cerimônia.
     * Requisito: Apenas o Scrum Master pode concluir a cerimônia.
     */
    function concludeCeremony(string memory _code) external whenNotPaused {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        if (!ds.ceremonyExists[_code]) revert CeremonyNotFound();
        ScrumPokerStorage.Ceremony storage ceremony = ds.ceremonies[_code];
        if (!ceremony.active) revert CeremonyNotActive();
        if (msg.sender != ceremony.scrumMaster && !_hasRole(ScrumPokerStorage.ADMIN_ROLE, msg.sender)) {
            revert NotAuthorized();
        }

        ceremony.endTime = block.timestamp;
        ceremony.active = false;

        emit CeremonyConcluded(_code, ceremony.endTime, ceremony.sprintNumber);
    }

    /**
     * @notice Obtém os detalhes de uma cerimônia.
     * @param _code Código único da cerimônia.
     */
    function getCeremony(string memory _code) external view returns (
        string memory code,
        uint256 sprintNumber,
        uint256 startTime,
        uint256 endTime,
        address scrumMaster,
        bool active,
        address[] memory participants
    ) {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        if (!ds.ceremonyExists[_code]) revert CeremonyNotFound();
        
        ScrumPokerStorage.Ceremony storage ceremony = ds.ceremonies[_code];
        return (
            ceremony.code,
            ceremony.sprintNumber,
            ceremony.startTime,
            ceremony.endTime,
            ceremony.scrumMaster,
            ceremony.active,
            ceremony.participants
        );
    }

    /**
     * @notice Verifica se uma cerimônia existe.
     * @param _code Código da cerimônia.
     * @return bool Verdadeiro se a cerimônia existir.
     */
    function ceremonyExists(string memory _code) external view returns (bool) {
        return ScrumPokerStorage.diamondStorage().ceremonyExists[_code];
    }

    /**
     * @notice Verifica se um participante solicitou entrada em uma cerimônia.
     * @param _code Código da cerimônia.
     * @param _participant Endereço do participante.
     * @return bool Verdadeiro se o participante solicitou entrada.
     */
    function hasRequestedEntry(string memory _code, address _participant) external view returns (bool) {
        return ScrumPokerStorage.diamondStorage().hasRequestedEntry[_code][_participant];
    }

    /**
     * @notice Verifica se um participante foi aprovado em uma cerimônia.
     * @param _code Código da cerimônia.
     * @param _participant Endereço do participante.
     * @return bool Verdadeiro se o participante foi aprovado.
     */
    function isApproved(string memory _code, address _participant) external view returns (bool) {
        return ScrumPokerStorage.diamondStorage().ceremonyApproved[_code][_participant];
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
     * @dev Converte um uint para string.
     * @param _i O número a ser convertido.
     * @return O número como string.
     */
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }

    // Evento para controle de acesso
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
}