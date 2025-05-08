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
            // Permitir apenas funções específicas quando pausado
            bytes4 unpauseSelector = bytes4(keccak256("unpause()"));
            bytes4 withdrawFundsSelector = bytes4(keccak256("withdrawFunds()"));
            
            require(
                selector_ == unpauseSelector || selector_ == withdrawFundsSelector,
                "ScrumPokerDiamond: contrato pausado"
            );
        }
        super._beforeFallback(facet_, selector_);
    }

    /**
     * @dev Implementação da função receive() para aceitar ETH.
     */
    receive() external payable {}
}