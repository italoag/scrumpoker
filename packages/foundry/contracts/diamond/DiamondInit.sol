// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@solidity-lib/diamond/Diamond.sol";
import "./ScrumPokerStorage.sol";

/**
 * @title DiamondInit
 * @dev Contrato de inicialização para o ScrumPokerDiamond.
 * Este contrato é usado para inicializar todas as facetas do Diamond em uma única transação.
 */
contract DiamondInit {
    using SafeERC20 for IERC20;

    /**
     * @notice Inicializa todas as facetas do Diamond.
     * @param _name Nome do token NFT.
     * @param _symbol Símbolo do token NFT.
     */
    function init(
        string memory _name,
        string memory _symbol
    ) external {
        // Configura o storage do Diamond
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Configurações para AdminFacet
        ds.exchangeRate = 1000000000000000000; // 1 ETH = 1 USD (valor padrão)
        ds.lastExchangeRateUpdate = block.timestamp;
        ds.vestingPeriod = 86400; // 1 dia de vesting (valor padrão)
        ds.nextTokenId = 0;
        ds.ceremonyCounter = 1;
        ds.paused = false;
    }
}