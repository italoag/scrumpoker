// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import {NFTFacet} from "../contracts/diamond/facets/NFTFacet.sol";
import {ScrumPokerStorage} from "../contracts/diamond/ScrumPokerStorage.sol";

/**
 * @title NFTPurchaseExample
 * @dev Script de exemplo demonstrando como usar as funcionalidades de compra de NFT
 */
contract NFTPurchaseExample is Script {
    NFTFacet public nftFacet;
    address public constant DIAMOND_ADDRESS = 0x1234567890123456789012345678901234567890; // Substituir pelo endereço real
    
    function run() external {
        // Conectar ao NFTFacet através do Diamond
        nftFacet = NFTFacet(DIAMOND_ADDRESS);
        
        // Obter chave privada do ambiente
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Exemplo de Uso do Sistema de Compra de NFT ===");
        console.log("Endereco do usuario:", deployer);
        
        // 1. Verificar se o usuário já possui um NFT
        demonstrateUserTokenCheck(deployer);
        
        // 2. Verificar cotação atual
        demonstrateExchangeRateCheck();
        
        // 3. Comprar NFT (se não possuir)
        demonstratePurchase(deployer);
        
        // 4. Verificar dados do badge
        demonstrateBadgeData(deployer);
        
        // 5. Verificar status de vesting
        demonstrateVestingCheck(deployer);
        
        vm.stopBroadcast();
    }
    
    function demonstrateUserTokenCheck(address user) internal view {
        console.log("\n--- Verificacao de NFT Existente ---");
        
        uint256 existingToken = nftFacet.getUserToken(user);
        
        if (existingToken == 0) {
            console.log("Usuario nao possui NFT. Pode prosseguir com a compra.");
        } else {
            console.log("Usuario ja possui NFT com ID:", existingToken);
            console.log("Endereco do dono:", nftFacet.ownerOf(existingToken));
        }
    }
    
    function demonstrateExchangeRateCheck() internal view {
        console.log("\n--- Verificacao da Cotacao ---");
        
        // Acessar storage através do Diamond
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        
        uint256 exchangeRate = ds.exchangeRate;
        uint256 lastUpdate = ds.lastExchangeRateUpdate;
        uint256 currentTime = block.timestamp;
        
        console.log("Taxa de cambio atual (wei):", exchangeRate);
        console.log("Taxa de cambio atual (ETH):", exchangeRate / 1e18);
        console.log("Ultima atualizacao:", lastUpdate);
        console.log("Tempo atual:", currentTime);
        
        uint256 timeSinceUpdate = currentTime - lastUpdate;
        console.log("Tempo desde ultima atualizacao (segundos):", timeSinceUpdate);
        
        if (timeSinceUpdate > 86400) { // 24 horas
            console.log("AVISO: Cotacao desatualizada! Necessaria atualizacao.");
        } else {
            console.log("Cotacao esta atualizada.");
        }
    }
    
    function demonstratePurchase(address user) internal {
        console.log("\n--- Tentativa de Compra de NFT ---");
        
        // Verificar se já possui NFT
        uint256 existingToken = nftFacet.getUserToken(user);
        if (existingToken != 0) {
            console.log("Usuario ja possui NFT. Pulando compra.");
            return;
        }
        
        // Obter taxa de câmbio
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        uint256 exchangeRate = ds.exchangeRate;
        
        // Verificar saldo
        uint256 userBalance = user.balance;
        console.log("Saldo do usuario (wei):", userBalance);
        console.log("Valor necessario (wei):", exchangeRate);
        
        if (userBalance < exchangeRate) {
            console.log("ERRO: Saldo insuficiente para compra.");
            return;
        }
        
        // Tentar comprar NFT
        try nftFacet.purchaseNFT{value: exchangeRate}(
            "Usuario Exemplo",
            "ipfs://QmExampleHash123456789"
        ) {
            console.log("NFT comprado com sucesso!");
            
            // Verificar novo token
            uint256 newToken = nftFacet.getUserToken(user);
            console.log("Novo token ID:", newToken);
            
        } catch Error(string memory reason) {
            console.log("Erro na compra:", reason);
        } catch (bytes memory) {
            console.log("Erro desconhecido na compra.");
        }
    }
    
    function demonstrateBadgeData(address user) internal view {
        console.log("\n--- Dados do Badge ---");
        
        uint256 tokenId = nftFacet.getUserToken(user);
        if (tokenId == 0) {
            console.log("Usuario nao possui NFT para consultar dados.");
            return;
        }
        
        try nftFacet.getBadgeData(tokenId) returns (
            string memory userName,
            address userAddress,
            uint256 ceremoniesParticipated,
            uint256 votesCast,
            ScrumPokerStorage.SprintResult[] memory sprintResults,
            string memory externalURI
        ) {
            console.log("Nome do usuario:", userName);
            console.log("Endereco do usuario:", userAddress);
            console.log("Cerimonias participadas:", ceremoniesParticipated);
            console.log("Votos realizados:", votesCast);
            console.log("URI externa:", externalURI);
            console.log("Resultados de sprints:", sprintResults.length);
            
        } catch Error(string memory reason) {
            console.log("Erro ao obter dados do badge:", reason);
        }
    }
    
    function demonstrateVestingCheck(address user) internal view {
        console.log("\n--- Verificacao de Vesting ---");
        
        uint256 tokenId = nftFacet.getUserToken(user);
        if (tokenId == 0) {
            console.log("Usuario nao possui NFT para verificar vesting.");
            return;
        }
        
        bool isVested = nftFacet.isVested(user);
        console.log("NFT esta vested:", isVested);
        
        if (isVested) {
            console.log("Usuario pode participar de votacoes.");
        } else {
            console.log("Usuario ainda esta no periodo de vesting.");
        }
    }
    
    /**
     * @dev Exemplo de como um admin retiraria fundos
     */
    function demonstrateAdminWithdrawal() external {
        console.log("\n--- Retirada de Fundos (Admin) ---");
        
        // Verificar saldo do contrato
        uint256 contractBalance = address(nftFacet).balance;
        console.log("Saldo do contrato (wei):", contractBalance);
        console.log("Saldo do contrato (ETH):", contractBalance / 1e18);
        
        if (contractBalance == 0) {
            console.log("Nenhum fundo para retirar.");
            return;
        }
        
        // Obter chave privada do admin
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        address admin = vm.addr(adminPrivateKey);
        
        vm.startBroadcast(adminPrivateKey);
        
        try nftFacet.withdrawFunds() {
            console.log("Fundos retirados com sucesso!");
            console.log("Novo saldo do contrato:", address(nftFacet).balance);
            
        } catch Error(string memory reason) {
            console.log("Erro na retirada:", reason);
        }
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev Exemplo de como fazer reembolso quando pausado
     */
    function demonstrateRefund() external {
        console.log("\n--- Reembolso de NFT ---");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Verificar se possui NFT
        uint256 tokenId = nftFacet.getUserToken(deployer);
        if (tokenId == 0) {
            console.log("Usuario nao possui NFT para reembolsar.");
            return;
        }
        
        // Verificar se o contrato está pausado
        ScrumPokerStorage.DiamondStorage storage ds = ScrumPokerStorage.diamondStorage();
        if (!ds.paused) {
            console.log("Contrato nao esta pausado. Reembolso nao disponivel.");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        uint256 balanceBefore = deployer.balance;
        
        try nftFacet.refundNFT() {
            console.log("Reembolso realizado com sucesso!");
            console.log("Saldo anterior (wei):", balanceBefore);
            console.log("Saldo atual (wei):", deployer.balance);
            console.log("Valor reembolsado (wei):", deployer.balance - balanceBefore);
            
        } catch Error(string memory reason) {
            console.log("Erro no reembolso:", reason);
        }
        
        vm.stopBroadcast();
    }
}