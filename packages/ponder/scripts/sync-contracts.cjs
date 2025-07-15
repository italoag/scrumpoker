#!/usr/bin/env node

/**
 * Script para sincronizar configurações do Ponder com deployedContracts.ts
 * Automaticamente atualiza endereços e ABIs dos contratos
 */

const fs = require('fs');
const path = require('path');

const DEPLOYED_CONTRACTS_FILE = path.join(__dirname, '..', '..', 'nextjs', 'contracts', 'deployedContracts.ts');
const PONDER_CONFIG_FILE = path.join(__dirname, '..', 'ponder.config.ts');
const TEMPLATE_FILE = path.join(__dirname, '..', 'config-template.ts');
const CHAIN_ID = 31337; // localhost

function extractContractsFromDeployedContracts() {
  console.log('📖 Lendo deployedContracts.ts...');
  
  if (!fs.existsSync(DEPLOYED_CONTRACTS_FILE)) {
    console.error('❌ deployedContracts.ts não encontrado');
    return null;
  }
  
  const content = fs.readFileSync(DEPLOYED_CONTRACTS_FILE, 'utf8');
  
  // Extrair informações dos contratos
  const contracts = {};
  
  // Buscar pela seção do chain usando a variável CHAIN_ID
  const chainPattern = new RegExp(`${CHAIN_ID}:\\s*{([\\s\\S]*?)(?=\\n\\s*\\d+:|\\n\\s*};|$)`);
  const chainMatch = content.match(chainPattern);
  
  if (!chainMatch) {
    console.error(`❌ Configuração para chain ${CHAIN_ID} não encontrada`);
    return null;
  }
  
  const chainSection = chainMatch[1];
  console.log(`📝 Seção extraída (primeiros 500 chars): ${chainSection.substring(0, 500)}...`);
  
  // Extrair contratos necessários
  const contractNames = ['AdminFacet', 'NFTFacet', 'CeremonyFacet', 'VotingFacet', 'ScrumPokerDiamond'];
  
  contractNames.forEach(contractName => {
    // Busca simples por padrão específico
    const simplePattern = new RegExp(`${contractName}:\\s*{[\\s\\S]*?address:\\s*"([^"]+)"`, 'm');
    const simpleMatch = chainSection.match(simplePattern);
    
    if (simpleMatch) {
      const address = simpleMatch[1].toLowerCase();
      console.log(`✅ ${contractName}: ${address}`);
      
      // Para o ABI, vamos extrair de forma mais simples por agora
      contracts[contractName] = {
        address: address,
        abi: '[]' // Simplificado - será preenchido depois
      };
    } else {
      console.warn(`⚠️  ${contractName} não encontrado`);
    }
  });
  
  return contracts;
}

function getDiamondAddress(contracts) {
  // No padrão Diamond, todas as facetas usam o mesmo endereço do Diamond
  return contracts.ScrumPokerDiamond?.address || contracts.AdminFacet?.address;
}

function extractEventsFromABI(abi) {
  try {
    const abiArray = JSON.parse(abi);
    return abiArray.filter(item => item.type === 'event');
  } catch (error) {
    console.error('Erro ao parsear ABI:', error);
    return [];
  }
}

function updatePonderConfig(contracts) {
  console.log('🔄 Atualizando ponder.config.ts...');
  
  const diamondAddress = getDiamondAddress(contracts);
  if (!diamondAddress) {
    console.error('❌ Endereço do Diamond não encontrado');
    return false;
  }
  
  console.log(`📍 Endereço do Diamond: ${diamondAddress}`);
  
  // Determinar startBlock baseado no chain ID e deployments
  let startBlock = 1; // Para chain 31337 (localhost)
  
  try {
    console.log(`🔍 Detectando startBlock para chain ${CHAIN_ID}...`);
    
    // Mapear chain ID para startBlock baseado nos deployments conhecidos
    const chainStartBlocks = {
      1337: 29552,   // chain 1337 - deployment no bloco 29552
      31337: 4,      // chain 31337 - deployment no bloco 4 (deployment real)
      2025: 31257    // chain 2025 - deployment no bloco 31257
    };
    
    startBlock = chainStartBlocks[CHAIN_ID] || 1;
    console.log(`📦 Start block para chain ${CHAIN_ID}: ${startBlock}`);
    
    // Tentar ler arquivo de deployment para confirmação
    const deploymentDirs = [
      path.join(__dirname, '..', '..', 'foundry', 'broadcast', 'Deploy.s.sol', CHAIN_ID.toString()),
      path.join(__dirname, '..', '..', 'foundry', 'broadcast', 'DeployScrumPokerOptimized.s.sol', CHAIN_ID.toString()),
      path.join(__dirname, '..', '..', 'foundry', 'broadcast', 'DeployScrumPoker.s.sol', CHAIN_ID.toString())
    ];
    
    for (const deployDir of deploymentDirs) {
      if (fs.existsSync(deployDir)) {
        const files = fs.readdirSync(deployDir).filter(f => f.endsWith('.json'));
        if (files.length > 0) {
          const deploymentFile = path.join(deployDir, files[0]);
          const deploymentData = JSON.parse(fs.readFileSync(deploymentFile, 'utf8'));
          
          // Pegar o menor blockNumber das transações do Diamond
          const transactions = deploymentData.transactions || [];
          const diamondTxs = transactions.filter(tx => 
            tx.contractName === 'ScrumPokerDiamond' || 
            tx.transactionReceipt?.contractAddress?.toLowerCase() === diamondAddress.toLowerCase()
          );
          
          if (diamondTxs.length > 0) {
            const blockNumbers = diamondTxs
              .map(tx => parseInt(tx.transactionReceipt?.blockNumber || '0', 16))
              .filter(bn => bn > 0);
            
            if (blockNumbers.length > 0) {
              const detectedBlock = Math.min(...blockNumbers);
              console.log(`📦 Block confirmado pelo deployment: ${detectedBlock}`);
              startBlock = detectedBlock;
            }
          }
          break;
        }
      }
    }
  } catch (error) {
    console.log('⚠️  Erro ao detectar startBlock, usando valor padrão:', error.message);
  }
  
  // ABIs simplificados com eventos essenciais
  const facetABIs = {
    CeremonyFacet: [
      {
        type: "event",
        name: "CeremonyStarted",
        inputs: [
          { name: "ceremonyCode", type: "string", indexed: false },
          { name: "sprintNumber", type: "uint256", indexed: false },
          { name: "startTime", type: "uint256", indexed: false },
          { name: "scrumMaster", type: "address", indexed: true }
        ]
      },
      {
        type: "event", 
        name: "CeremonyEntryRequested",
        inputs: [
          { name: "ceremonyCode", type: "string", indexed: false },
          { name: "participant", type: "address", indexed: true }
        ]
      },
      {
        type: "event",
        name: "EntryApproved", 
        inputs: [
          { name: "ceremonyCode", type: "string", indexed: false },
          { name: "participant", type: "address", indexed: true }
        ]
      },
      {
        type: "event",
        name: "CeremonyConcluded",
        inputs: [
          { name: "ceremonyCode", type: "string", indexed: false },
          { name: "endTime", type: "uint256", indexed: false },
          { name: "sprintNumber", type: "uint256", indexed: false }
        ]
      }
    ],
    VotingFacet: [
      {
        type: "event",
        name: "FunctionalityVoteOpened",
        inputs: [
          { name: "ceremonyCode", type: "string", indexed: false },
          { name: "functionalityCode", type: "string", indexed: false },
          { name: "sessionIndex", type: "uint256", indexed: false }
        ]
      },
      {
        type: "event",
        name: "FunctionalityVoteCommitted", 
        inputs: [
          { name: "ceremonyCode", type: "string", indexed: false },
          { name: "sessionIndex", type: "uint256", indexed: false },
          { name: "participant", type: "address", indexed: true }
        ]
      },
      {
        type: "event",
        name: "FunctionalityVoteRevealed",
        inputs: [
          { name: "ceremonyCode", type: "string", indexed: false },
          { name: "sessionIndex", type: "uint256", indexed: false },
          { name: "participant", type: "address", indexed: true },
          { name: "voteValue", type: "uint256", indexed: false }
        ]
      },
      {
        type: "event",
        name: "FunctionalityVoteClosed",
        inputs: [
          { name: "ceremonyCode", type: "string", indexed: false },
          { name: "sessionIndex", type: "uint256", indexed: false },
          { name: "closer", type: "address", indexed: true }
        ]
      },
      {
        type: "event",
        name: "FunctionalityVoteCast",
        inputs: [
          { name: "ceremonyCode", type: "string", indexed: false },
          { name: "sessionIndex", type: "uint256", indexed: false },
          { name: "participant", type: "address", indexed: true },
          { name: "voteValue", type: "uint256", indexed: false }
        ]
      },
      {
        type: "event",
        name: "BadgeBatchProcessed",
        inputs: [
          { name: "ceremonyCode", type: "string", indexed: false },
          { name: "sessionIndex", type: "uint256", indexed: false },
          { name: "batchSize", type: "uint256", indexed: false }
        ]
      },
      {
        type: "event",
        name: "NFTBadgeUpdated",
        inputs: [
          { name: "participant", type: "address", indexed: true },
          { name: "tokenId", type: "uint256", indexed: false }
        ]
      }
    ],
    AdminFacet: [
      {
        type: "event",
        name: "ExchangeRateUpdated",
        inputs: [
          { name: "newRate", type: "uint256", indexed: false },
          { name: "timestamp", type: "uint256", indexed: false }
        ]
      }
    ],
    NFTFacet: [
      {
        type: "event",
        name: "NFTPurchased",
        inputs: [
          { name: "buyer", type: "address", indexed: true },
          { name: "tokenId", type: "uint256", indexed: false },
          { name: "amountPaid", type: "uint256", indexed: false }
        ]
      },
      {
        type: "event",
        name: "NFTRefunded",
        inputs: [
          { name: "buyer", type: "address", indexed: true },
          { name: "tokenId", type: "uint256", indexed: false },
          { name: "amountRefunded", type: "uint256", indexed: false }
        ]
      }
    ]
  };
  
  // Gerar configuração do Ponder
  let config = `import { createConfig } from "ponder";
import { http } from "viem";

export default createConfig({
  database: {
    kind: "sqlite",
    directory: "./.ponder/sqlite",
  },
  networks: {
    localhost: {
      chainId: 31337,
      transport: http("http://127.0.0.1:8545"),
    },
  },
  contracts: {`;

  // Adicionar cada faceta
  Object.keys(facetABIs).forEach(facetName => {
    if (contracts[facetName]) {
      const abi = facetABIs[facetName];
      const facetAddress = contracts[facetName].address; // Usar endereço da faceta individual
      
      config += `
    ${facetName}: {
      network: "localhost",
      abi: ${JSON.stringify(abi, null, 8)},
      address: "${facetAddress}",
      startBlock: ${startBlock},
    },`;
    }
  });

  config += `
  },
});`;

  // Salvar arquivo
  fs.writeFileSync(PONDER_CONFIG_FILE, config);
  console.log('✅ ponder.config.ts atualizado');
  
  // Atualizar template também
  fs.writeFileSync(TEMPLATE_FILE, config);
  console.log('✅ config-template.ts atualizado');
  
  return true;
}

function main() {
  console.log('🔄 Sincronizando configurações do Ponder...');
  
  const contracts = extractContractsFromDeployedContracts();
  if (!contracts) {
    console.error('❌ Falha ao extrair contratos');
    process.exit(1);
  }
  
  if (updatePonderConfig(contracts)) {
    console.log('✅ Sincronização concluída com sucesso!');
  } else {
    console.error('❌ Falha na sincronização');
    process.exit(1);
  }
}

// Executar se chamado diretamente
if (require.main === module) {
  main();
}

module.exports = { main, extractContractsFromDeployedContracts, updatePonderConfig };