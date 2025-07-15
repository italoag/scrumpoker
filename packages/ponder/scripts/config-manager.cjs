#!/usr/bin/env node

/**
 * Gerenciador de configuração do Ponder
 * Permite fazer backup e restaurar configurações
 */

const fs = require('fs');
const path = require('path');

const CONFIG_FILE = path.join(__dirname, '..', 'ponder.config.ts');
const TEMPLATE_FILE = path.join(__dirname, '..', 'config-template.ts');
const BACKUP_FILE = path.join(__dirname, '..', 'ponder.config.backup.ts');

function backup() {
  console.log('📁 Fazendo backup da configuração...');
  
  if (!fs.existsSync(CONFIG_FILE)) {
    console.error('❌ Arquivo ponder.config.ts não encontrado');
    return false;
  }
  
  fs.copyFileSync(CONFIG_FILE, BACKUP_FILE);
  console.log('✅ Backup criado em ponder.config.backup.ts');
  return true;
}

function restore() {
  console.log('🔄 Restaurando configuração do template...');
  
  if (!fs.existsSync(TEMPLATE_FILE)) {
    console.error('❌ Template não encontrado');
    return false;
  }
  
  // Fazer backup antes de restaurar
  if (fs.existsSync(CONFIG_FILE)) {
    backup();
  }
  
  fs.copyFileSync(TEMPLATE_FILE, CONFIG_FILE);
  console.log('✅ Configuração restaurada do template');
  return true;
}

function restoreFromBackup() {
  console.log('🔄 Restaurando configuração do backup...');
  
  if (!fs.existsSync(BACKUP_FILE)) {
    console.error('❌ Backup não encontrado');
    return false;
  }
  
  fs.copyFileSync(BACKUP_FILE, CONFIG_FILE);
  console.log('✅ Configuração restaurada do backup');
  return true;
}

function fix() {
  console.log('🔧 Corrigindo configuração...');
  
  if (!fs.existsSync(CONFIG_FILE)) {
    console.error('❌ Arquivo ponder.config.ts não encontrado');
    return false;
  }
  
  let configContent = fs.readFileSync(CONFIG_FILE, 'utf8');
  
  // Corrigir startBlock
  configContent = configContent.replace(/startBlock:\s*0,/g, 'startBlock: 4,');
  
  // Garantir que todos os contratos tenham o mesmo endereço
  const diamondAddress = "0xe1DA8919f262Ee86f9BE05059C9280142CF23f48";
  configContent = configContent.replace(
    /address:\s*"[^"]*",/g, 
    `address: "${diamondAddress}",`
  );
  
  fs.writeFileSync(CONFIG_FILE, configContent);
  console.log('✅ Configuração corrigida');
  return true;
}

// Processar argumentos da linha de comando
const command = process.argv[2];

switch (command) {
  case 'backup':
    backup();
    break;
  case 'restore':
    restore();
    break;
  case 'restore-backup':
    restoreFromBackup();
    break;
  case 'fix':
    fix();
    break;
  default:
    console.log(`
📋 Uso: node config-manager.js <command>

Comandos disponíveis:
  backup         - Faz backup da configuração atual
  restore        - Restaura configuração do template
  restore-backup - Restaura configuração do backup
  fix            - Corrige problemas comuns na configuração

Exemplos:
  node config-manager.js backup
  node config-manager.js fix
  node config-manager.js restore
    `);
    break;
}