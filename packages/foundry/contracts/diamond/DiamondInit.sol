// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@solidity-lib/diamond/Diamond.sol";
import "./ScrumPokerStorage.sol";
import "./facets/AdminFacet.sol";
import "./facets/NFTFacet.sol";
import "./facets/CeremonyFacet.sol";
import "./facets/VotingFacet.sol";

/**
 * @title DiamondInit
 * @dev Contrato de inicialização para o ScrumPokerDiamond.
 * Este contrato é usado para inicializar todas as facetas do Diamond em uma única transação.
 */
contract DiamondInit {
    using SafeERC20 for IERC20;

    /**
     * @notice Inicializa todas as facetas do Diamond.
     * @param _initialExchangeRate Taxa de câmbio inicial (valor em wei equivalente a 1 dólar).
     * @param _vestingPeriod Período de vesting em segundos.
     * @param _admin Endereço do administrador inicial.
     */
    function init(
        uint256 _initialExchangeRate,
        uint256 _vestingPeriod,
        address _admin
    ) external {
        // Inicializa a faceta de administração
        AdminFacet adminFacet = AdminFacet(address(this));
        adminFacet.initialize(_initialExchangeRate, _vestingPeriod, _admin);
        
        // Inicializa a faceta de NFT
        NFTFacet nftFacet = NFTFacet(address(this));
        nftFacet.initializeNFT("ScrumPokerBadge", "SPB");
        
        // Inicializa a faceta de cerimônia
        CeremonyFacet ceremonyFacet = CeremonyFacet(address(this));
        ceremonyFacet.initializeCeremony();
        
        // Inicializa a faceta de votação
        VotingFacet votingFacet = VotingFacet(address(this));
        votingFacet.initializeVoting();
    }
}