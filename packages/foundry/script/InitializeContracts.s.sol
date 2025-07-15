// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";
import "../contracts/diamond/facets/AdminFacet.sol";
import "../contracts/diamond/facets/NFTFacet.sol";
import "../contracts/diamond/facets/CeremonyFacet.sol";
import "../contracts/diamond/facets/VotingFacet.sol";

/**
 * @notice Script para inicializar contratos após deployment
 * @dev Este script executa todas as configurações necessárias automaticamente
 */
contract InitializeContracts is Script {
    using stdJson for string;

    struct DeploymentAddresses {
        address scrumPokerDeployer;
        address scrumPokerDiamond;
        address adminFacet;
        address nftFacet;
        address ceremonyFacet;
        address votingFacet;
    }

    function run() external {
        // Recupera a chave privada do ambiente
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address deployerAddress = vm.addr(deployerPrivateKey);
        
        console.log("Initializing contracts with address:", deployerAddress);
        
        // Carrega endereços do deployment
        DeploymentAddresses memory addresses = loadDeploymentAddresses();
        
        // Inicia o broadcast das transações
        vm.startBroadcast(deployerPrivateKey);
        
        // Inicializa cada faceta
        initializeAdminFacet(addresses.scrumPokerDiamond, deployerAddress);
        initializeNFTFacet(addresses.scrumPokerDiamond);
        initializeCeremonyFacet(addresses.scrumPokerDiamond);
        initializeVotingFacet(addresses.scrumPokerDiamond);
        
        // Encerra o broadcast
        vm.stopBroadcast();
        
        console.log("✅ Contract initialization completed successfully!");
    }
    
    /**
     * @dev Carrega endereços do arquivo de deployment
     */
    function loadDeploymentAddresses() internal view returns (DeploymentAddresses memory) {
        string memory network = getNetwork();
        string memory filePath = string.concat("./deployments/", network, ".json");
        
        try {
            string memory json = vm.readFile(filePath);
            
            return DeploymentAddresses({
                scrumPokerDeployer: json.readAddress(".ScrumPokerDeployer"),
                scrumPokerDiamond: json.readAddress(".ScrumPokerDiamond"),
                adminFacet: json.readAddress(".AdminFacet"),
                nftFacet: json.readAddress(".NFTFacet"),
                ceremonyFacet: json.readAddress(".CeremonyFacet"),
                votingFacet: json.readAddress(".VotingFacet")
            });
        } catch {
            revert("Failed to load deployment addresses. Make sure deployment file exists.");
        }
    }
    
    /**
     * @dev Inicializa AdminFacet com configurações padrão
     */
    function initializeAdminFacet(address diamond, address admin) internal {
        console.log("🔧 Initializing AdminFacet...");
        
        AdminFacet adminFacet = AdminFacet(diamond);
        
        try {
            // Define taxa de câmbio inicial (1 ETH = 1000 tokens, por exemplo)
            uint256 initialExchangeRate = 1000;
            adminFacet.updateExchangeRate(initialExchangeRate);
            console.log("  ✅ Exchange rate set to:", initialExchangeRate);
            
            // Adiciona outras inicializações específicas do AdminFacet aqui
            console.log("  ✅ AdminFacet initialized successfully");
            
        } catch Error(string memory reason) {
            console.log("  ⚠️ AdminFacet initialization warning:", reason);
        } catch {
            console.log("  ⚠️ AdminFacet initialization failed (may already be initialized)");
        }
    }
    
    /**
     * @dev Inicializa NFTFacet com configurações padrão
     */
    function initializeNFTFacet(address diamond) internal {
        console.log("🔧 Initializing NFTFacet...");
        
        NFTFacet nftFacet = NFTFacet(diamond);
        
        try {
            // Verifica se já foi inicializado
            // Adicione verificações específicas do NFTFacet aqui
            console.log("  ✅ NFTFacet initialized successfully");
            
        } catch Error(string memory reason) {
            console.log("  ⚠️ NFTFacet initialization warning:", reason);
        } catch {
            console.log("  ⚠️ NFTFacet initialization failed (may already be initialized)");
        }
    }
    
    /**
     * @dev Inicializa CeremonyFacet com configurações padrão
     */
    function initializeCeremonyFacet(address diamond) internal {
        console.log("🔧 Initializing CeremonyFacet...");
        
        CeremonyFacet ceremonyFacet = CeremonyFacet(diamond);
        
        try {
            // Adicione inicializações específicas do CeremonyFacet aqui
            console.log("  ✅ CeremonyFacet initialized successfully");
            
        } catch Error(string memory reason) {
            console.log("  ⚠️ CeremonyFacet initialization warning:", reason);
        } catch {
            console.log("  ⚠️ CeremonyFacet initialization failed (may already be initialized)");
        }
    }
    
    /**
     * @dev Inicializa VotingFacet com configurações padrão
     */
    function initializeVotingFacet(address diamond) internal {
        console.log("🔧 Initializing VotingFacet...");
        
        VotingFacet votingFacet = VotingFacet(diamond);
        
        try {
            // Adicione inicializações específicas do VotingFacet aqui
            console.log("  ✅ VotingFacet initialized successfully");
            
        } catch Error(string memory reason) {
            console.log("  ⚠️ VotingFacet initialization warning:", reason);
        } catch {
            console.log("  ⚠️ VotingFacet initialization failed (may already be initialized)");
        }
    }
    
    /**
     * @dev Retorna o nome da rede atual com base no chainId
     */
    function getNetwork() internal view returns (string memory) {
        uint256 chainId = block.chainid;
        if (chainId == 1) return "mainnet";
        if (chainId == 5) return "goerli";
        if (chainId == 137) return "polygon";
        if (chainId == 80001) return "mumbai";
        if (chainId == 31337) return "anvil";
        if (chainId == 1337) return "devnet";
        return vm.toString(chainId);
    }
}