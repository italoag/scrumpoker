// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@solidity-lib/diamond/Diamond.sol";
import "./ScrumPokerStorage.sol";
import "forge-std/console.sol";

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
     * @param _admin Endereço do administrador inicial.
     */
    function init(
        string memory _name,
        string memory _symbol,
        address _admin
    ) external {
        console.log("DiamondInit.init() called");
        console.log("Admin address:", _admin);
        console.log("msg.sender:", msg.sender);
        
        // Configura o storage do Diamond
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        // Configurações para AdminFacet
        ds.exchangeRate = 1000000; // 1000000 WEI como solicitado
        ds.lastExchangeRateUpdate = block.timestamp;
        ds.vestingPeriod = 86400; // 1 dia de vesting (valor padrão)
        ds.nextTokenId = 0;
        ds.ceremonyCounter = 1;
        ds.paused = false;
        
        console.log("Basic values set, exchange rate:", ds.exchangeRate);
        
        // CRÍTICO: Inicializar AccessControl - conceder roles ao admin especificado
        require(_admin != address(0), "Admin address cannot be zero");
        ds.roles[ScrumPokerStorage.ADMIN_ROLE][_admin] = true;
        ds.roles[ScrumPokerStorage.PRICE_UPDATER_ROLE][_admin] = true;
        ds.roles[ScrumPokerStorage.SCRUM_MASTER_ROLE][_admin] = true;
        
        console.log("Roles granted to admin:", _admin);
        console.log("DiamondInit.init() completed successfully");
    }
}