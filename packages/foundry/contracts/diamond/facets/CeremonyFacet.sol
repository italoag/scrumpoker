// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../ScrumPokerStorage.sol";
import "../library/StringUtils.sol";
import "../library/ValidationUtils.sol";

/**
 * @title CeremonyFacet
 * @dev Faceta para gerenciar as cerimônias (sprints) do ScrumPoker.
 * Implementa a criação de cerimônias, solicitação de entrada e aprovação de participantes.
 */
contract CeremonyFacet is Initializable, ReentrancyGuardUpgradeable {
    using StringUtils for string;
    using ValidationUtils for address;
    using ValidationUtils for uint256;
    // Eventos
    event CeremonyStarted(string ceremonyCode, uint256 sprintNumber, uint256 startTime, address indexed scrumMaster);
    event CeremonyEntryRequested(string ceremonyCode, address indexed participant);
    event EntryApproved(string ceremonyCode, address indexed participant);
    event CeremonyConcluded(string ceremonyCode, uint256 endTime, uint256 sprintNumber);
    // Evento para controle de acesso
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    // Erros
    error CeremonyNotFound();
    error NotAuthorized();
    error EntryAlreadyRequested();
    error EntryNotRequested();
    error ParticipantAlreadyApproved();
    error NFTRequired();
    error CeremonyNotActive();


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
        uint256 length = 0; // Inicialização explícita para melhorar a legibilidade e evitar problemas
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

    /**
     * @dev Modificador que verifica se o contrato não está pausado.
     */
    modifier whenNotPaused() {
        require(!ScrumPokerStorage.diamondStorage().paused, "CeremonyFacet: pausado");
        _;
    }

    /**
     * @dev Inicializa o contrato CeremonyFacet e verifica/inicializa o versionamento do storage.
     */
    function initializeCeremony() external initializer {
        __ReentrancyGuard_init();
        
        // Inicializa ou verifica o storage versionado
        ScrumPokerStorage.initializeStorage();
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
        // Verifica se o storage está inicializado e na versão correta
        ScrumPokerStorage.requireCorrectStorageVersion();
        
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Gera um código único para a cerimônia
        // Uso de abi.encode para prevenir colisões de hash
        // Use abi.encodePacked instead of abi.encode to produce a clean UTF-8 string without ABI metadata
        string memory code = string(abi.encodePacked("CEREMONY", uint2str(ds.ceremonyCounter)));
        
        // Gera o hash do código para usar como chave otimizada
        bytes32 codeHash = ScrumPokerStorage.registerCeremonyCode(code);
        
        // Verificação de segurança - garante que o código não existe já
        // Verifica tanto no formato otimizado quanto no formato legado
        if (ds.ceremonyExists[codeHash]) {
            revert ScrumPokerStorage.CeremonyAlreadyExists(code);
        }
        
        ds.ceremonyCounter++;

        // Inicializa a estrutura da cerimônia usando o layout de armazenamento otimizado
        ScrumPokerStorage.Ceremony storage ceremony = ds.ceremoniesByHash[codeHash];
        ceremony.codeHash = codeHash;
        ceremony.code = code;
        ceremony.sprintNumber = _sprintNumber;
        ceremony.startTime = block.timestamp;
        ceremony.scrumMaster = msg.sender;
        ceremony.active = true;

        // Marca a cerimônia como existente no formato otimizado
        ds.ceremonyExists[codeHash] = true;
        
        // Mantenha a compatibilidade com código existente (legado)

        ds.ceremonyCodeToHash[code] = codeHash;
        
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
        
        // Verifica existência usando a função helper que suporta ambos os formatos
        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        if (ds.userToken[msg.sender] == 0) revert NFTRequired();
        
        // Obtém o hash do código para armazenamento otimizado
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHash(_code);
        
        // Verifica se já solicitou entrada, verificando primeiro o formato otimizado
        if (ds.hasRequestedEntry[codeHash][msg.sender]) revert EntryAlreadyRequested();

        // Armazena no novo formato otimizado
        ds.hasRequestedEntry[codeHash][msg.sender] = true;
        
        // Mantém retrocompatibilidade

        
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
        
        // Verifica se a cerimônia existe usando a função helper
        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        
        // Obtém a cerimônia usando o helper que suporta ambos os formatos
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        
        // Verifica autorização
        if (msg.sender != ceremony.scrumMaster && !_hasRole(ScrumPokerStorage.ADMIN_ROLE, msg.sender)) {
            revert NotAuthorized();
        }
        
        // Obtém o hash otimizado
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHash(_code);
        
        // Verifica se solicitou entrada
        if (!ds.hasRequestedEntry[codeHash][_participant]) revert EntryNotRequested();
        
        // Verifica se já está aprovado
        if (ds.ceremonyApproved[codeHash][_participant]) revert ParticipantAlreadyApproved();

        // Aprova no formato otimizado
        ds.ceremonyApproved[codeHash][_participant] = true;
        
        // Mantém compatibilidade com o formato legado

        
        // Adiciona à lista de participantes e atualiza vesting
        ceremony.participants.push(_participant);
        ds.vestingStart[_participant] = block.timestamp;
        emit EntryApproved(_code, _participant);
    }

    /**
     * @notice Conclui a cerimônia.
     * @param _code Código único da cerimônia.
     * Requisito: Apenas o Scrum Master pode concluir a cerimônia.
     */
    function concludeCeremony(string memory _code) external whenNotPaused {
        // Verifica se a cerimônia existe usando a função helper
        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        
        // Usa o helper para obter a cerimônia, que funciona tanto com o novo quanto com o formato legado
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
        
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
        // Verifica existência usando a função helper
        if (!ScrumPokerStorage.ceremonyExists(_code)) revert CeremonyNotFound();
        
        // Usa o helper para obter a cerimônia do formato adequado
        ScrumPokerStorage.Ceremony storage ceremony = ScrumPokerStorage.getCeremony(_code);
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
        // Usa a função helper que verifica ambos os formatos
        return ScrumPokerStorage.ceremonyExists(_code);
    }

    /**
     * @notice Verifica se um participante solicitou entrada em uma cerimônia.
     * @param _code Código da cerimônia.
     * @param _participant Endereço do participante.
     * @return bool Verdadeiro se o participante solicitou entrada.
     */
    function hasRequestedEntry(string memory _code, address _participant) external view returns (bool) {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Verifica em ambos os formatos (otimizado e legado)
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHashView(_code);
        return ds.hasRequestedEntry[codeHash][_participant];
    }

    /**
     * @notice Verifica se um participante foi aprovado em uma cerimônia.
     * @param _code Código da cerimônia.
     * @param _participant Endereço do participante.
     * @return bool Verdadeiro se o participante foi aprovado.
     */
    function isApproved(string memory _code, address _participant) external view returns (bool) {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Verifica em ambos os formatos (otimizado e legado)
        bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHashView(_code);
        return ds.ceremonyApproved[codeHash][_participant];
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

}