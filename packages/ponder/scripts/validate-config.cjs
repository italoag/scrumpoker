#!/usr/bin/env node

/**
 * Script de validação para configuração do Ponder
 * Verifica se todos os contratos têm a configuração correta após codegen
 */

const fs = require('fs');
const path = require('path');

const CONFIG_FILE = path.join(__dirname, '..', 'ponder.config.ts');
const EXPECTED_START_BLOCK = 4;
const EXPECTED_ADDRESS = "0xe1DA8919f262Ee86f9BE05059C9280142CF23f48";

function validateConfig() {
  console.log('🔍 Validando configuração do Ponder...');
  
  if (!fs.existsSync(CONFIG_FILE)) {
    console.error('❌ Arquivo ponder.config.ts não encontrado');
    process.exit(1);
  }
  
  const configContent = fs.readFileSync(CONFIG_FILE, 'utf8');
  
  // Verificar startBlock
  const startBlockMatches = configContent.match(/startBlock:\s*(\d+)/g);
  if (!startBlockMatches) {
    console.error('❌ Nenhum startBlock encontrado na configuração');
    process.exit(1);
  }
  
  let hasIncorrectStartBlock = false;
  startBlockMatches.forEach(match => {
    const value = parseInt(match.match(/\d+/)[0]);
    if (value !== EXPECTED_START_BLOCK) {
      console.error(`❌ startBlock incorreto encontrado: ${value}, esperado: ${EXPECTED_START_BLOCK}`);
      hasIncorrectStartBlock = true;
    }
  });
  
  // Verificar endereços
  const addressMatches = configContent.match(/address:\s*"([^"]+)"/g);
  if (!addressMatches) {
    console.error('❌ Nenhum endereço encontrado na configuração');
    process.exit(1);
  }
  
  let hasIncorrectAddress = false;
  addressMatches.forEach(match => {
    const address = match.match(/"([^"]+)"/)[1];
    if (address !== EXPECTED_ADDRESS) {
      console.error(`❌ Endereço incorreto encontrado: ${address}, esperado: ${EXPECTED_ADDRESS}`);
      hasIncorrectAddress = true;
    }
  });
  
  // Verificar se todos os contratos necessários estão presentes
  const requiredContracts = ['CeremonyFacet', 'VotingFacet', 'AdminFacet', 'NFTFacet'];
  let hasMissingContracts = false;
  
  requiredContracts.forEach(contract => {
    if (!configContent.includes(`${contract}:`)) {
      console.error(`❌ Contrato ausente: ${contract}`);
      hasMissingContracts = true;
    }
  });
  
  if (hasIncorrectStartBlock || hasIncorrectAddress || hasMissingContracts) {
    console.error('❌ Configuração inválida encontrada');
    process.exit(1);
  }
  
  console.log('✅ Configuração do Ponder válida');
}

function fixConfig() {
  console.log('🔧 Corrigindo configuração...');
  
  let configContent = fs.readFileSync(CONFIG_FILE, 'utf8');
  
  // Corrigir startBlock
  configContent = configContent.replace(/startBlock:\s*0,/g, `startBlock: ${EXPECTED_START_BLOCK},`);
  
  // Escrever arquivo corrigido
  fs.writeFileSync(CONFIG_FILE, configContent);
  
  console.log('✅ Configuração corrigida');
}

// Executar validação
try {
  validateConfig();
} catch (error) {
  console.log('⚠️  Problemas encontrados, tentando corrigir...');
  fixConfig();
  validateConfig();
}