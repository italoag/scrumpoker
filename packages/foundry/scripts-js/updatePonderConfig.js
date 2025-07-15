import { readFileSync, writeFileSync, existsSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * Script para atualizar automaticamente a configuração do Ponder após deployment
 * Este script lê os endereços do último deployment e atualiza o ponder.config.ts
 */

function getLatestDeploymentAddresses(network = "anvil") {
  const deploymentPath = join(__dirname, "..", "deployments", `${network}.json`);
  
  if (!existsSync(deploymentPath)) {
    console.error(`❌ Deployment file not found: ${deploymentPath}`);
    return null;
  }

  try {
    const deployment = JSON.parse(readFileSync(deploymentPath, "utf8"));
    console.log("📋 Found deployment addresses:", deployment);
    return deployment;
  } catch (error) {
    console.error(`❌ Error reading deployment file: ${error.message}`);
    return null;
  }
}

function updatePonderConfig(addresses, network = "localhost", chainId = 31337, startBlock = 4) {
  const ponderConfigPath = join(__dirname, "..", "..", "ponder", "ponder.config.ts");
  
  if (!existsSync(ponderConfigPath)) {
    console.error(`❌ Ponder config not found: ${ponderConfigPath}`);
    return false;
  }

  // Lê o arquivo atual para preservar as ABIs
  let currentConfig;
  try {
    currentConfig = readFileSync(ponderConfigPath, "utf8");
  } catch (error) {
    console.error(`❌ Error reading ponder config: ${error.message}`);
    return false;
  }

  // Extrai as ABIs atuais usando regex
  const abiRegex = /abi:\s*\[([\s\S]*?)\]/g;
  const abis = {};
  let match;

  // Mapeia as facetas para suas ABIs
  const facetNames = ["CeremonyFacet", "VotingFacet", "AdminFacet", "NFTFacet"];
  
  facetNames.forEach(facetName => {
    const facetRegex = new RegExp(`${facetName}:[\\s\\S]*?abi:\\s*\\[([\\s\\S]*?)\\]`, 'g');
    const facetMatch = facetRegex.exec(currentConfig);
    if (facetMatch) {
      abis[facetName] = facetMatch[1];
    }
  });

  // Gera a nova configuração
  const newConfig = `import { createConfig } from "ponder";
import { http } from "viem";

export default createConfig({
  database: {
    kind: "sqlite",
    directory: "./.ponder/sqlite",
  },
  networks: {
    ${network}: {
      chainId: ${chainId},
      transport: http("http://127.0.0.1:8545"),
    },
  },
  contracts: {
    CeremonyFacet: {
      network: "${network}",
      abi: [${abis.CeremonyFacet || ''}],
      address: "${addresses.ScrumPokerDiamond}",
      startBlock: ${startBlock},
    },
    VotingFacet: {
      network: "${network}",
      abi: [${abis.VotingFacet || ''}],
      address: "${addresses.ScrumPokerDiamond}",
      startBlock: ${startBlock},
    },
    AdminFacet: {
      network: "${network}",
      abi: [${abis.AdminFacet || ''}],
      address: "${addresses.ScrumPokerDiamond}",
      startBlock: ${startBlock},
    },
    NFTFacet: {
      network: "${network}",
      abi: [${abis.NFTFacet || ''}],
      address: "${addresses.ScrumPokerDiamond}",
      startBlock: ${startBlock},
    },
  },
});`;

  try {
    writeFileSync(ponderConfigPath, newConfig);
    console.log("✅ Ponder config updated successfully!");
    console.log(`📍 All facets now point to: ${addresses.ScrumPokerDiamond}`);
    console.log(`🔢 Start block: ${startBlock}`);
    return true;
  } catch (error) {
    console.error(`❌ Error writing ponder config: ${error.message}`);
    return false;
  }
}

function main() {
  console.log("🔄 Updating Ponder configuration...");
  
  // Pega argumentos da linha de comando
  const args = process.argv.slice(2);
  const network = args[0] || "anvil";
  const chainId = parseInt(args[1]) || 31337;
  const startBlock = parseInt(args[2]) || 4;
  
  console.log(`📡 Network: ${network}`);
  console.log(`⛓️  Chain ID: ${chainId}`);
  console.log(`🎯 Start Block: ${startBlock}`);
  
  // Obtém endereços do último deployment
  const addresses = getLatestDeploymentAddresses(network);
  if (!addresses) {
    process.exit(1);
  }
  
  // Atualiza a configuração do Ponder
  const success = updatePonderConfig(addresses, "localhost", chainId, startBlock);
  if (!success) {
    process.exit(1);
  }
  
  console.log("🎉 Ponder configuration update completed!");
}

// Executa apenas se chamado diretamente
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { updatePonderConfig, getLatestDeploymentAddresses };