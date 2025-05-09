// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";
import "../contracts/diamond/ScrumPokerDeployer.sol";
import "../contracts/diamond/facets/AdminFacet.sol";
import "../contracts/diamond/facets/NFTFacet.sol";
import "../contracts/diamond/facets/CeremonyFacet.sol";
import "../contracts/diamond/facets/VotingFacet.sol";

/**
 * @notice Script simplificado para deploy do ScrumPoker
 * @dev Este script usa uma abordagem direta sem dependências complexas
 */
contract DeployScrumPokerSimple is Script {
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
        // Recupera a chave privada do ambiente ou usa uma padrão para testes
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        
        // Endereço do deployer derivado da chave privada
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deploying with address:", deployerAddress);
        
        // Inicia o broadcast das transações
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy do ScrumPokerDeployer
        ScrumPokerDeployer scrumDeployer = new ScrumPokerDeployer();
        console.log("ScrumPokerDeployer deployed at:", address(scrumDeployer));
        
        // Obtemos os endereços das facetas antes do deploy para posteriormente verificar
        address adminFacetAddress;
        address nftFacetAddress;
        address ceremonyFacetAddress;
        address votingFacetAddress;
        
        // Os endereços das facetas estão expostos no facetDeployer do ScrumPokerDeployer
        adminFacetAddress = scrumDeployer.facetDeployer().deployAdminFacet();
        nftFacetAddress = scrumDeployer.facetDeployer().deployNFTFacet();
        ceremonyFacetAddress = scrumDeployer.facetDeployer().deployCeremonyFacet();
        votingFacetAddress = scrumDeployer.facetDeployer().deployVotingFacet();
        
        // Deploy de todos os contratos ScrumPoker
        address diamondAddress = scrumDeployer.deployAll(deployerAddress);
        console.log("ScrumPokerDiamond deployed at:", diamondAddress);
        console.log("AdminFacet deployed at:", adminFacetAddress);
        console.log("NFTFacet deployed at:", nftFacetAddress);
        console.log("CeremonyFacet deployed at:", ceremonyFacetAddress);
        console.log("VotingFacet deployed at:", votingFacetAddress);
        
        // Encerra o broadcast
        vm.stopBroadcast();
        
        // Cria uma estrutura para armazenar todos os endereços
        DeploymentAddresses memory addresses = DeploymentAddresses({
            scrumPokerDeployer: address(scrumDeployer),
            scrumPokerDiamond: diamondAddress,
            adminFacet: adminFacetAddress,
            nftFacet: nftFacetAddress,
            ceremonyFacet: ceremonyFacetAddress,
            votingFacet: votingFacetAddress
        });
        
        // Salva as informações do deployment
        saveDeploymentInfo(addresses);
    }
    
    /**
     * @dev Salva as informações do deployment em um arquivo JSON
     */
    function saveDeploymentInfo(DeploymentAddresses memory addresses) internal {
        // Criando um JSON com informações detalhadas do deployment
        string memory json = '{';
        json = string.concat(json, '"ScrumPokerDeployer": "', vm.toString(addresses.scrumPokerDeployer), '",');
        json = string.concat(json, '"ScrumPokerDiamond": "', vm.toString(addresses.scrumPokerDiamond), '",');
        json = string.concat(json, '"AdminFacet": "', vm.toString(addresses.adminFacet), '",');
        json = string.concat(json, '"NFTFacet": "', vm.toString(addresses.nftFacet), '",');
        json = string.concat(json, '"CeremonyFacet": "', vm.toString(addresses.ceremonyFacet), '",');
        json = string.concat(json, '"VotingFacet": "', vm.toString(addresses.votingFacet), '"');
        json = string.concat(json, '}');
        
        string memory network = getNetwork();
        string memory filePath = string.concat("./deployments/", network, ".json");
        
        // Usamos o método nativo do Forge para escrever no arquivo
        // Trocamos o caminho para ser relativo ao diretório raiz do projeto
        string memory fullPath = string.concat(vm.projectRoot(), "/deployments/", network, ".json");
        
        // Criamos o arquivo diretamente
        vm.writeFile(fullPath, json);
        
        console.log("Deployment addresses written to:", filePath);
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
        if (chainId == 2025) return "devnet";
        return vm.toString(chainId);
    }
}
