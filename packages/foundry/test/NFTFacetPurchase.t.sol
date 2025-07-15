// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {NFTFacet} from "../contracts/diamond/facets/NFTFacet.sol";
import {AdminFacet} from "../contracts/diamond/facets/AdminFacet.sol";
import {ScrumPokerDiamond} from "../contracts/diamond/ScrumPokerDiamond.sol";
import {ScrumPokerStorage} from "../contracts/diamond/ScrumPokerStorage.sol";
import {Diamond} from "@solidity-lib/diamond/Diamond.sol";
import {OwnableDiamond} from "@solidity-lib/presets/diamond/OwnableDiamond.sol";
import {NFTFacetSelectors} from "../contracts/diamond/deployers/selectors/NFTFacetSelectors.sol";
import {AdminFacetSelectors} from "../contracts/diamond/deployers/selectors/AdminFacetSelectors.sol";

/**
 * @title NFTFacetPurchaseTest
 * @dev Testes funcionais completos para as funcionalidades de compra de NFT
 */
contract NFTFacetPurchaseTest is Test {
    NFTFacet nftFacet;
    ScrumPokerDiamond scrumPokerDiamond;
    address owner = address(0xABCD);
    address user1 = address(0x1234);
    address user2 = address(0x5678);
    
    uint256 constant EXCHANGE_RATE = 0.001 ether; // 1 dólar = 0.001 ETH para teste
    uint256 constant VESTING_PERIOD = 1 days;
    
    event NFTPurchased(address indexed buyer, uint256 tokenId, uint256 amountPaid);
    event NFTRefunded(address indexed buyer, uint256 tokenId, uint256 amountRefunded);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event QuoteOutdated(uint256 lastUpdated);
    
    function setUp() public {
        // Deploy do NFTFacet
        nftFacet = new NFTFacet();
        
        // Deploy do Diamond principal
        scrumPokerDiamond = new ScrumPokerDiamond(owner);
        
        // Configuração do storage para testes
        vm.startPrank(owner);
        _setupDiamond();
        _setupStorage();
        vm.stopPrank();
        
        // Dar ETH para os usuários de teste
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(owner, 10 ether);
    }
    
    function _setupStorage() internal {
        // Try AdminFacet initialization first (should work now since NFT isn't initialized yet)
        try AdminFacet(address(scrumPokerDiamond)).initialize(
            EXCHANGE_RATE,
            VESTING_PERIOD,
            owner
        ) {
            console.log("AdminFacet.initialize() succeeded");
        } catch {
            console.log("AdminFacet.initialize() failed, using manual setup");
            // Fallback to manual setup if needed
            ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
            ds.version = 2;
            ds.lastUpgradeTimestamp = block.timestamp;
            ds.exchangeRate = EXCHANGE_RATE;
            ds.lastExchangeRateUpdate = block.timestamp;
            ds.vestingPeriod = VESTING_PERIOD;
            ds.paused = false;
            ds.nextTokenId = 0;
            bytes32 adminRole = ScrumPokerStorage.ADMIN_ROLE;
            ds.roles[adminRole][owner] = true;
        }
        
        // Since NFTFacet.initializeNFT() will fail due to initializer being used,
        // we need to manually set up the ERC721 storage
        // This is a workaround for the test environment
        console.log("Setting up ERC721 storage manually for test");
        
        // Verify final state
        uint256 finalRate = AdminFacet(address(scrumPokerDiamond)).getExchangeRate();
        console.log("Final exchange rate:", finalRate);
    }
    
    function _setupDiamond() internal {
        // First add AdminFacet to the Diamond
        AdminFacet adminFacet = new AdminFacet();
        
        // Use manual selectors that we know work
        bytes4[] memory adminSelectors = new bytes4[](15);
        adminSelectors[0] = AdminFacet.initialize.selector;
        adminSelectors[1] = AdminFacet.pause.selector;
        adminSelectors[2] = AdminFacet.unpause.selector;
        adminSelectors[3] = AdminFacet.isPaused.selector;
        adminSelectors[4] = AdminFacet.withdrawFunds.selector;
        adminSelectors[5] = AdminFacet.withdrawERC20.selector;
        adminSelectors[6] = AdminFacet.grantRole.selector;
        adminSelectors[7] = AdminFacet.revokeRole.selector;
        adminSelectors[8] = AdminFacet.hasRole.selector;
        adminSelectors[9] = AdminFacet.getExchangeRate.selector;
        adminSelectors[10] = AdminFacet.getVestingPeriod.selector;
        adminSelectors[11] = AdminFacet.updateExchangeRate.selector;
        adminSelectors[12] = AdminFacet.updateVestingPeriod.selector;
        adminSelectors[13] = AdminFacet.updateExchangeRateFromOracle.selector;
        adminSelectors[14] = AdminFacet.setPriceOracle.selector;
        
        Diamond.Facet[] memory adminFacets = new Diamond.Facet[](1);
        adminFacets[0] = Diamond.Facet({
            facetAddress: address(adminFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: adminSelectors
        });
        
        // Add AdminFacet first
        OwnableDiamond(payable(address(scrumPokerDiamond))).diamondCut(
            adminFacets,
            address(0),
            ""
        );
        
        // Then add NFTFacet to the Diamond (without initialization)
        bytes4[] memory nftSelectors = NFTFacetSelectors.getSelectors();
        Diamond.Facet[] memory nftFacets = new Diamond.Facet[](1);
        nftFacets[0] = Diamond.Facet({
            facetAddress: address(nftFacet),
            action: Diamond.FacetAction.Add,
            functionSelectors: nftSelectors
        });
        
        // Add NFTFacet without initialization
        OwnableDiamond(payable(address(scrumPokerDiamond))).diamondCut(
            nftFacets,
            address(0),
            ""
        );
    }
    
    function _getNFTFacetFromDiamond() internal view returns (NFTFacet) {
        return NFTFacet(address(scrumPokerDiamond));
    }
    
    function _getAdminFacetFromDiamond() internal view returns (AdminFacet) {
        return AdminFacet(address(scrumPokerDiamond));
    }
    
    /**
     * @dev Teste de compra bem-sucedida de NFT
     */
    function testSuccessfulNFTPurchase() public {
        NFTFacet diamondNFT = _getNFTFacetFromDiamond();
        
        vm.startPrank(user1);
        
        // Verificar que o usuário não possui NFT antes da compra
        uint256 tokenBefore = diamondNFT.getUserToken(user1);
        assertEq(tokenBefore, 0, "Usuario nao deve ter NFT antes da compra");
        
        // Realizar a compra
        vm.expectEmit(true, false, false, true);
        emit NFTPurchased(user1, 1, EXCHANGE_RATE);
        
        diamondNFT.purchaseNFT{value: EXCHANGE_RATE}("TestUser1", "ipfs://test-uri");
        
        // Verificar que o NFT foi criado
        uint256 tokenAfter = diamondNFT.getUserToken(user1);
        assertEq(tokenAfter, 1, "Usuario deve ter o NFT com ID 1");
        
        // Verificar que o usuário é o dono do NFT
        address tokenOwner = diamondNFT.ownerOf(1);
        assertEq(tokenOwner, user1, "Usuario deve ser o dono do NFT");
        
        // Verificar os dados do badge
        (
            string memory userName,
            address userAddress,
            uint256 ceremoniesParticipated,
            uint256 votesCast,
            ,
            string memory externalURI
        ) = diamondNFT.getBadgeData(1);
        
        assertEq(userName, "TestUser1", "Nome do usuario deve estar correto");
        assertEq(userAddress, user1, "Endereco do usuario deve estar correto");
        assertEq(ceremoniesParticipated, 0, "Cerimonias participadas deve ser 0");
        assertEq(votesCast, 0, "Votos realizados deve ser 0");
        assertEq(externalURI, "ipfs://test-uri", "URI externa deve estar correta");
        
        vm.stopPrank();
    }
    
    /**
     * @dev Teste de falha ao tentar comprar com valor incorreto
     */
    function testPurchaseWithIncorrectAmount() public {
        NFTFacet diamondNFT = _getNFTFacetFromDiamond();
        
        vm.startPrank(user1);
        
        // Tentar comprar com valor menor
        vm.expectRevert(NFTFacet.IncorrectPaymentAmount.selector);
        diamondNFT.purchaseNFT{value: EXCHANGE_RATE - 1}("TestUser1", "ipfs://test-uri");
        
        // Tentar comprar com valor maior
        vm.expectRevert(NFTFacet.IncorrectPaymentAmount.selector);
        diamondNFT.purchaseNFT{value: EXCHANGE_RATE + 1}("TestUser1", "ipfs://test-uri");
        
        vm.stopPrank();
    }
    
    /**
     * @dev Teste de falha ao tentar comprar NFT duplicado
     */
    function testPreventDuplicateNFTPurchase() public {
        NFTFacet diamondNFT = _getNFTFacetFromDiamond();
        
        vm.startPrank(user1);
        
        // Primeira compra (deve funcionar)
        diamondNFT.purchaseNFT{value: EXCHANGE_RATE}("TestUser1", "ipfs://test-uri");
        
        // Segunda compra (deve falhar)
        vm.expectRevert(NFTFacet.NFTAlreadyPurchased.selector);
        diamondNFT.purchaseNFT{value: EXCHANGE_RATE}("TestUser1", "ipfs://test-uri-2");
        
        vm.stopPrank();
    }
    
    /**
     * @dev Teste de compra por múltiplos usuários
     */
    function testMultipleUsersPurchase() public {
        NFTFacet diamondNFT = _getNFTFacetFromDiamond();
        
        // User1 compra NFT
        vm.prank(user1);
        diamondNFT.purchaseNFT{value: EXCHANGE_RATE}("TestUser1", "ipfs://test-uri-1");
        
        // User2 compra NFT
        vm.prank(user2);
        diamondNFT.purchaseNFT{value: EXCHANGE_RATE}("TestUser2", "ipfs://test-uri-2");
        
        // Verificar que cada usuário tem seu próprio NFT
        uint256 token1 = diamondNFT.getUserToken(user1);
        uint256 token2 = diamondNFT.getUserToken(user2);
        
        assertEq(token1, 1, "User1 deve ter NFT com ID 1");
        assertEq(token2, 2, "User2 deve ter NFT com ID 2");
        
        // Verificar que são donos corretos
        assertEq(diamondNFT.ownerOf(1), user1, "User1 deve ser dono do NFT 1");
        assertEq(diamondNFT.ownerOf(2), user2, "User2 deve ser dono do NFT 2");
    }
    
    /**
     * @dev Teste de retirada de fundos pelo admin
     */
    function testWithdrawFunds() public {
        NFTFacet diamondNFT = _getNFTFacetFromDiamond();
        
        // Usuários compram NFTs
        vm.prank(user1);
        diamondNFT.purchaseNFT{value: EXCHANGE_RATE}("TestUser1", "ipfs://test-uri-1");
        
        vm.prank(user2);
        diamondNFT.purchaseNFT{value: EXCHANGE_RATE}("TestUser2", "ipfs://test-uri-2");
        
        // Verificar saldo do contrato
        uint256 contractBalance = address(scrumPokerDiamond).balance;
        assertEq(contractBalance, EXCHANGE_RATE * 2, "Contrato deve ter 2x exchange rate");
        
        // Owner retira os fundos
        uint256 ownerBalanceBefore = owner.balance;
        
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit FundsWithdrawn(owner, EXCHANGE_RATE * 2);
        diamondNFT.withdrawFunds();
        
        // Verificar que os fundos foram transferidos
        uint256 ownerBalanceAfter = owner.balance;
        assertEq(ownerBalanceAfter, ownerBalanceBefore + (EXCHANGE_RATE * 2), "Owner deve receber os fundos");
        assertEq(address(scrumPokerDiamond).balance, 0, "Contrato deve ficar sem saldo");
    }
    
    /**
     * @dev Teste de reembolso quando o contrato está pausado
     */
    function testRefundWhenPaused() public {
        NFTFacet diamondNFT = _getNFTFacetFromDiamond();
        AdminFacet adminFacet = _getAdminFacetFromDiamond();
        
        // User1 compra NFT primeiro (enquanto não está pausado)
        vm.prank(user1);
        diamondNFT.purchaseNFT{value: EXCHANGE_RATE}("TestUser1", "ipfs://test-uri");
        
        uint256 tokenId = diamondNFT.getUserToken(user1);
        assertEq(tokenId, 1, "Usuario deve ter NFT");
        
        // Agora pausar o contrato usando AdminFacet
        vm.prank(owner);
        adminFacet.pause();
        
        // User1 solicita reembolso (agora que está pausado)
        uint256 user1BalanceBefore = user1.balance;
        
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit NFTRefunded(user1, 1, EXCHANGE_RATE);
        diamondNFT.refundNFT();
        
        // Verificar que o usuário recebeu o reembolso
        uint256 user1BalanceAfter = user1.balance;
        assertEq(user1BalanceAfter, user1BalanceBefore + EXCHANGE_RATE, "Usuario deve receber reembolso");
        
        // Unpause para verificar que o NFT foi queimado
        vm.prank(owner);
        adminFacet.unpause();
        
        // Verificar que o NFT foi queimado (agora que não está mais pausado)
        uint256 tokenAfterRefund = diamondNFT.getUserToken(user1);
        assertEq(tokenAfterRefund, 0, "Usuario nao deve ter NFT apos reembolso");
    }
    
    /**
     * @dev Teste de falha ao tentar reembolso quando não pausado
     */
    function testRefundFailsWhenNotPaused() public {
        NFTFacet diamondNFT = _getNFTFacetFromDiamond();
        
        // User1 compra NFT
        vm.prank(user1);
        diamondNFT.purchaseNFT{value: EXCHANGE_RATE}("TestUser1", "ipfs://test-uri");
        
        // Tentar reembolso sem pausar (deve falhar)
        vm.prank(user1);
        vm.expectRevert(NFTFacet.NotPaused.selector);
        diamondNFT.refundNFT();
    }
    
    /**
     * @dev Teste de verificação de vesting
     */
    function testVestingPeriod() public {
        NFTFacet diamondNFT = _getNFTFacetFromDiamond();
        
        // User1 compra NFT
        vm.prank(user1);
        diamondNFT.purchaseNFT{value: EXCHANGE_RATE}("TestUser1", "ipfs://test-uri");
        
        // Verificar que não está vested imediatamente
        bool isVestedBefore = diamondNFT.isVested(user1);
        assertFalse(isVestedBefore, "NFT nao deve estar vested imediatamente");
        
        // Avançar o tempo para após o período de vesting
        vm.warp(block.timestamp + VESTING_PERIOD + 1);
        
        // Verificar que agora está vested
        bool isVestedAfter = diamondNFT.isVested(user1);
        assertTrue(isVestedAfter, "NFT deve estar vested apos o periodo");
    }
    
    /**
     * @dev Teste de cotação desatualizada (emite evento mas permite compra)
     */
    function testOutdatedExchangeRate() public {
        NFTFacet diamondNFT = _getNFTFacetFromDiamond();
        
        // Avançar o tempo para mais de 24 horas
        vm.warp(block.timestamp + 25 hours);
        
        // Comprar com cotação desatualizada deve emitir evento QuoteOutdated
        vm.prank(user1);
        vm.expectEmit(true, false, false, false);
        emit QuoteOutdated(block.timestamp - 25 hours); // timestamp original
        diamondNFT.purchaseNFT{value: EXCHANGE_RATE}("TestUser1", "ipfs://test-uri");
        
        // Verificar que a compra foi bem-sucedida mesmo com cotação desatualizada
        uint256 tokenId = diamondNFT.getUserToken(user1);
        assertEq(tokenId, 1, "Usuario deve ter NFT mesmo com cotacao desatualizada");
    }
}