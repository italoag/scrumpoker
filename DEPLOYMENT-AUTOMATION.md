# 🚀 Automated Deployment System

Este sistema automatiza completamente o processo de deployment dos contratos ScrumPoker e configuração do indexador Ponder.

## 📋 Visão Geral

O sistema de deployment automatizado resolve o problema de configurações manuais após cada deployment, garantindo que:

- ✅ Contratos sejam deployados corretamente
- ✅ ABIs sejam gerados automaticamente  
- ✅ Configuração do Ponder seja atualizada com novos endereços
- ✅ Contratos sejam inicializados com configurações padrão
- ✅ Banco de dados do Ponder seja limpo para reindexação

## 🛠️ Scripts Disponíveis

### Scripts Principais

#### `yarn deploy:auto` (Recomendado)
Executa deployment completo e automatizado:
```bash
yarn deploy:auto
```

#### `yarn deploy:full`
Deployment com output detalhado:
```bash
yarn deploy:full
```

#### `yarn deploy:quick`
Deployment rápido sem inicializações:
```bash
yarn deploy:quick
```

### Scripts Específicos

#### `yarn foundry:update:ponder`
Atualiza apenas a configuração do Ponder:
```bash
yarn foundry:update:ponder [network] [chainId] [startBlock]
```

#### `yarn foundry:init:contracts`
Executa apenas inicializações dos contratos:
```bash
yarn foundry:init:contracts
```

#### `yarn foundry:generate:abis`
Gera apenas os ABIs:
```bash
yarn foundry:generate:abis
```

## 🔧 Opções Avançadas

### Parâmetros do Script Automatizado

```bash
# Exemplos de uso avançado
yarn foundry:deploy:auto --network localhost --start-block 1
yarn foundry:deploy:auto --verbose --skip-init
yarn foundry:deploy:auto --skip-ponder
```

#### Opções Disponíveis:
- `--network <name>`: Nome da rede (padrão: anvil)
- `--chain-id <id>`: ID da chain (padrão: 31337)
- `--start-block <num>`: Bloco inicial para indexação (padrão: 4)
- `--verbose`: Mostra output detalhado
- `--skip-ponder`: Pula configuração do Ponder
- `--skip-init`: Pula inicialização dos contratos
- `--help`: Mostra ajuda

## 📁 Estrutura de Arquivos

```
packages/foundry/
├── scripts-js/
│   ├── automatedDeploy.js          # Script principal de deployment
│   ├── updatePonderConfig.js       # Atualização do Ponder
│   ├── generateCombinedDiamondAbi.js
│   └── generateTsAbis.js
├── script/
│   ├── DeployScrumPoker.s.sol      # Script de deployment Solidity
│   └── InitializeContracts.s.sol   # Script de inicialização
└── deployments/
    ├── anvil.json                  # Endereços do deployment
    └── anvil-summary.json          # Resumo detalhado
```

## 🔄 Fluxo de Deployment

1. **Compilação**: `forge build`
2. **Deploy**: Executa `DeployScrumPoker.s.sol`
3. **Geração de ABIs**: Cria ABIs combinados e TypeScript
4. **Atualização do Ponder**: Atualiza `ponder.config.ts` com novos endereços
5. **Inicialização**: Executa `InitializeContracts.s.sol`
6. **Restart do Ponder**: Limpa database e prepara para reindexação
7. **Resumo**: Gera relatório detalhado

## 📊 Output do Deployment

Após o deployment bem-sucedido, você verá:

```
📊 DEPLOYMENT SUMMARY
=====================
🌐 Network: anvil
⛓️  Chain ID: 31337
🎯 Start Block: 4
💎 Diamond Address: 0x1121cBFfCEC885F26754d891f0f956045D1E3988
🏗️  Deployer: 0x...

🔧 Facet Addresses:
   AdminFacet: 0x...
   NFTFacet: 0x...
   CeremonyFacet: 0x...
   VotingFacet: 0x...

✅ All systems ready for use!
```

## 🔧 Configuração do Ponder

O script atualiza automaticamente `packages/ponder/ponder.config.ts`:

- ✅ Todos os facets apontam para o mesmo endereço Diamond
- ✅ StartBlock configurado corretamente
- ✅ ABIs preservados da configuração anterior
- ✅ Network e chainId atualizados

## 🚨 Solução de Problemas

### Erro: "Deployment file not found"
```bash
# Certifique-se que o deployment foi executado
yarn foundry:deploy
```

### Erro: "Ponder config not found"
```bash
# Verifique se o Ponder está configurado
ls packages/ponder/ponder.config.ts
```

### Erro: "Process already running"
```bash
# Para processos Ponder existentes
pkill -f ponder
```

## 🎯 Casos de Uso

### Desenvolvimento Local
```bash
# Deployment completo para desenvolvimento
yarn deploy:auto
```

### CI/CD
```bash
# Deployment sem inicializações para testes
yarn deploy:quick --skip-ponder
```

### Debugging
```bash
# Deployment com output detalhado
yarn deploy:full --verbose
```

### Atualização Rápida do Ponder
```bash
# Apenas atualiza configuração do Ponder
yarn foundry:update:ponder
```

## 📈 Benefícios

- 🎯 **Zero Configuração Manual**: Tudo automatizado
- ⚡ **Deployment Rápido**: Um comando para tudo
- 🔄 **Consistência**: Sempre mesmo processo
- 🛡️ **Segurança**: Verificações automáticas
- 📊 **Visibilidade**: Logs detalhados e resumos
- 🔧 **Flexibilidade**: Múltiplas opções de uso

## 🤝 Contribuição

Para adicionar novas funcionalidades ao sistema de deployment:

1. Modifique `automatedDeploy.js` para novos passos
2. Atualize `InitializeContracts.s.sol` para novas inicializações
3. Adicione scripts específicos conforme necessário
4. Atualize esta documentação

---

**💡 Dica**: Use sempre `yarn deploy:auto` para desenvolvimento local - é a forma mais rápida e segura de ter tudo funcionando!