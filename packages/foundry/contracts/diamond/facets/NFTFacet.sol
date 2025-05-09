// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../ScrumPokerStorage.sol";
import "../library/StringUtils.sol";
import "../library/ValidationUtils.sol";

/**
 * @title NFTFacet
 * @dev Faceta para gerenciar a funcionalidade de NFT (badges) do ScrumPoker.
 * Implementa a compra de NFTs, gerenciamento de metadados e visualização de dados dos badges.
 */
contract NFTFacet is 
    Initializable, 
    ERC721Upgradeable, 
    ERC721URIStorageUpgradeable, 
    ReentrancyGuardUpgradeable 
{
    using SafeERC20 for IERC20;
    using StringUtils for string;
    using ValidationUtils for address;
    using ValidationUtils for uint256;

    // Eventos
    event NFTPurchased(address indexed buyer, uint256 tokenId, uint256 amountPaid);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event NFTBadgeMinted(address indexed participant, uint256 tokenId, uint256 sprintNumber);
    event CotacaoOutdated(uint256 lastUpdated);

    // Erros
    error IncorrectPaymentAmount();
    error NFTAlreadyPurchased();
    error WithdrawalFailed();
    error NotAuthorized();

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
        require(!ScrumPokerStorage.diamondStorage().paused, "NFTFacet: pausado");
        _;
    }

    /**
     * @dev Inicializa o contrato NFTFacet.
     * @param _name Nome do token ERC721.
     * @param _symbol Símbolo do token ERC721.
     */
    function initializeNFT(
        string memory _name,
        string memory _symbol
    ) external initializer {
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        __ReentrancyGuard_init();
    }

    /**
     * @notice Permite a compra do NFT (badge) mediante o pagamento de 1 dólar em moeda nativa.
     * @param _userName Nome do usuário.
     * @param _externalURI URI para metadados externos (ex.: imagem/avatar).
     *
     * Se a cotação não foi atualizada há mais de 24 horas, emite o evento `CotacaoOutdated`.
     * Os fundos são mantidos no contrato para posterior retirada pelo owner (padrão de retirada).
     */
    function purchaseNFT(string memory _userName, string memory _externalURI) 
        external 
        payable 
        nonReentrant 
        whenNotPaused 
    {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Verifica se a cotação está atualizada
        _checkCotacaoOutdated(ds.lastExchangeRateUpdate);
        
        // Verifica o valor enviado
        if (msg.value != ds.exchangeRate) revert IncorrectPaymentAmount();
        
        // Verifica se o usuário já possui um NFT
        if (ds.userToken[msg.sender] != 0) revert NFTAlreadyPurchased();

        // Gera o tokenId utilizando pré-incremento (primeiro NFT terá tokenId 1)
        uint256 tokenId = ++ds.nextTokenId;
        _safeMint(msg.sender, tokenId);

        // Inicializa os metadados do badge
        ScrumPokerStorage.BadgeData storage badge = ds.badgeData[tokenId];
        badge.userName = _userName;
        badge.userAddress = msg.sender;
        badge.ceremoniesParticipated = 0;
        badge.votesCast = 0;
        badge.externalURI = _externalURI;
        ds.userToken[msg.sender] = tokenId;
        ds.vestingStart[msg.sender] = block.timestamp;

        // Emite evento de compra
        emit NFTPurchased(msg.sender, tokenId, msg.value);
    }

    /**
     * @notice Permite ao owner retirar os fundos acumulados no contrato.
     * Implementa o padrão de retirada (withdrawal pattern) para maior segurança.
     */
    function withdrawFunds() external nonReentrant onlyRole(ScrumPokerStorage.ADMIN_ROLE) {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert WithdrawalFailed();
        emit FundsWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Obtém os dados do badge (NFT) de um usuário.
     * @param tokenId ID do token a ser consultado.
     * @return userName Nome do usuário.
     * @return userAddress Endereço do usuário.
     * @return ceremoniesParticipated Número de cerimônias participadas.
     * @return votesCast Número de votos realizados.
     * @return sprintResults Resultados das cerimônias.
     * @return externalURI URI externo para metadados.
     */
    function getBadgeData(uint256 tokenId) external view returns (
        string memory userName,
        address userAddress,
        uint256 ceremoniesParticipated,
        uint256 votesCast,
        ScrumPokerStorage.SprintResult[] memory sprintResults,
        string memory externalURI
    ) {
        ScrumPokerStorage.BadgeData storage badge = ScrumPokerStorage.diamondStorage().badgeData[tokenId];
        return (
            badge.userName,
            badge.userAddress,
            badge.ceremoniesParticipated,
            badge.votesCast,
            badge.sprintResults,
            badge.externalURI
        );
    }

    /**
     * @notice Obtém o ID do token de um usuário.
     * @param user Endereço do usuário.
     * @return uint256 ID do token do usuário (0 se não possuir).
     */
    function getUserToken(address user) external view returns (uint256) {
        return ScrumPokerStorage.diamondStorage().userToken[user];
    }

    /**
     * @notice Verifica se um usuário está no período de vesting.
     * @param user Endereço do usuário.
     * @return bool Verdadeiro se o período de vesting já passou.
     */
    function isVested(address user) external view returns (bool) {
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        return block.timestamp >= ds.vestingStart[user] + ds.vestingPeriod;
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
     * @dev Função interna para verificar se a cotação está desatualizada e emitir o evento.
     * @param lastUpdate Timestamp da última atualização da cotação.
     */
    function _checkCotacaoOutdated(uint256 lastUpdate) internal {
        if (block.timestamp > lastUpdate + 86400) {
            emit CotacaoOutdated(lastUpdate);
        }
    }

    // Removido o override da função _burn para compatibilidade com OpenZeppelin
    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Atualiza o badge NFT com informações de participação em um sprint.
     * @param _participant Endereço do participante.
     * @param _tokenId ID do token NFT.
     * @param _sprintNumber Número do sprint.
     * @dev Esta função é chamada internamente pelo VotingFacet ao concluir uma cerimônia.
     */
    function updateBadgeForSprint(address _participant, uint256 _tokenId, uint256 _sprintNumber) 
        external 
        onlyRole(ScrumPokerStorage.ADMIN_ROLE) 
    {
        emit NFTBadgeMinted(_participant, _tokenId, _sprintNumber);
    }
}