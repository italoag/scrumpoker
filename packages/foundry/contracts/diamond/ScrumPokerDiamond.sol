// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@solidity-lib/diamond/Diamond.sol";
import "@solidity-lib/presets/diamond/OwnableDiamond.sol";
import "@solidity-lib/diamond/utils/DiamondERC165.sol";
import "./ScrumPokerStorage.sol";

/**
 * @title ScrumPokerDiamond
 * @dev Implementação do contrato principal ScrumPoker usando o padrão Diamond (EIP-2535)
 * com a biblioteca Solarity 3.1. Este contrato atua como proxy que delega chamadas
 * para várias facetas (contratos de implementação).
 */
contract ScrumPokerDiamond is OwnableDiamond, DiamondERC165 {
    // Eventos do contrato principal
    event EtherReceived(address indexed sender, uint256 amount);
    event MaxContributionUpdated(uint256 oldLimit, uint256 newLimit);
    
    // Limite máximo de contribuição em ETH (10 ETH inicialmente)
    uint256 public maxContribution = 10 ether;
    
    // Erro personalizado para contribuições acima do limite
    error ContributionTooLarge(uint256 sent, uint256 maxAllowed);

    /**
     * @dev Construtor que inicializa o contrato Diamond.
     * @param _initialOwner Endereço do proprietário inicial do contrato.
     */
    constructor(address _initialOwner) {
        // Inicializa o contrato como proprietário
        _transferOwnership(_initialOwner);
    }

    /**
     * @dev Sobrescreve a função _beforeFallback para adicionar verificação de pausa.
     * @param facet_ Endereço da faceta que será chamada.
     * @param selector_ Seletor da função que será chamada.
     */
    function _beforeFallback(address facet_, bytes4 selector_) internal override {
        // Verifica se o contrato está pausado (exceto para funções de emergência)
        if (ScrumPokerStorage.diamondStorage().paused) {
            // Lista expandida de seletores permitidos em modo de pausa
            bytes4 unpauseSelector = bytes4(keccak256("unpause()"));
            bytes4 withdrawFundsSelector = bytes4(keccak256("withdrawFunds()"));
            bytes4 isPausedSelector = bytes4(keccak256("isPaused()"));
            bytes4 ownerSelector = bytes4(keccak256("owner()"));
            bytes4 getExchangeRateSelector = bytes4(keccak256("getExchangeRate()"));
            bytes4 setMaxContributionSelector = bytes4(keccak256("setMaxContribution(uint256)"));
            
            require(
                selector_ == unpauseSelector ||
                selector_ == withdrawFundsSelector ||
                selector_ == isPausedSelector ||
                selector_ == ownerSelector ||
                selector_ == getExchangeRateSelector ||
                selector_ == setMaxContributionSelector,
                "ScrumPokerDiamond: contrato pausado"
            );
        }
        super._beforeFallback(facet_, selector_);
    }
    
    /**
     * @notice Define o limite máximo de contribuição em ETH.
     * @param _newLimit Novo limite máximo de contribuição.
     * @dev Apenas o owner pode chamar esta função.
     */
    function setMaxContribution(uint256 _newLimit) external {
        require(owner() == msg.sender, "ScrumPokerDiamond: apenas owner");
        uint256 oldLimit = maxContribution;
        maxContribution = _newLimit;
        emit MaxContributionUpdated(oldLimit, _newLimit);
    }

    /**
     * @dev Implementação da função receive() para aceitar ETH com validações.
     * Limita o valor que pode ser recebido e emite um evento para rastreabilidade.
     */
    receive() external payable {
        // Verificar se o valor enviado não excede o limite máximo
        if (msg.value > maxContribution) {
            revert ContributionTooLarge(msg.value, maxContribution);
        }
        
        // Emite evento para rastrear quem enviou ETH e quanto
        emit EtherReceived(msg.sender, msg.value);
    }
}