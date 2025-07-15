# Guia de Configuração do Ponder - ScrumPoker

## Problema Identificado

Após executar `yarn ponder:codegen`, os eventos de cerimônias param de aparecer no dashboard devido a alterações automáticas na configuração do Ponder.

### Principais Causas:

1. **startBlock alterado para 0**: O codegen às vezes redefine o `startBlock` para 0, causando reprocessamento desnecessário
2. **Perda de configurações**: Algumas configurações específicas podem ser perdidas durante a regeneração
3. **Conflitos de banco de dados**: Reprocessamento pode causar conflitos na base de dados

## Solução Implementada

### 1. Scripts de Validação e Correção

- **`scripts/validate-config.js`**: Valida se a configuração está correta
- **`scripts/config-manager.js`**: Gerencia backup e restauração de configurações
- **`config-template.ts`**: Template com configuração correta

### 2. Hooks Automáticos no package.json

```json
{
  "precodegen": "node scripts/config-manager.js backup",
  "postcodegen": "node scripts/config-manager.js fix && node scripts/validate-config.js",
  "predev": "node scripts/validate-config.js"
}
```

### 3. Configurações Críticas

- **startBlock**: Deve ser `15` para todos os contratos
- **address**: Deve ser o mesmo endereço do Diamond para todas as facetas
- **Contratos necessários**: CeremonyFacet, VotingFacet, AdminFacet, NFTFacet

## Como Usar

### Comandos Disponíveis

```bash
# Validar configuração atual
yarn validate

# Fazer backup da configuração
yarn config:backup

# Corrigir problemas na configuração
yarn config:fix

# Restaurar do template
yarn config:restore

# Executar codegen com proteção automática
yarn codegen

# Executar dev com validação automática
yarn dev
```

### Fluxo Recomendado

1. **Antes de qualquer mudança importante**:
   ```bash
   yarn config:backup
   ```

2. **Após codegen ou mudanças de schema**:
   ```bash
   yarn config:fix
   yarn validate
   ```

3. **Se algo der errado**:
   ```bash
   yarn config:restore
   ```

## Prevenção de Problemas Futuros

### 1. Sempre use os scripts de hook
Os hooks automáticos no package.json irão:
- Fazer backup antes do codegen
- Corrigir automaticamente após o codegen
- Validar antes de iniciar o dev

### 2. Monitore os logs
Os scripts de validação mostram exatamente o que está sendo corrigido:
```
🔍 Validando configuração do Ponder...
✅ Configuração do Ponder válida
```

### 3. Em caso de dúvida, restaure do template
O arquivo `config-template.ts` sempre contém a configuração correta e testada.

## Estrutura de Arquivos

```
packages/ponder/
├── ponder.config.ts           # Configuração atual
├── config-template.ts         # Template de configuração correta
├── ponder.config.backup.ts    # Backup automático
└── scripts/
    ├── validate-config.js     # Validação
    └── config-manager.js      # Gerenciamento
```

## Solução de Problemas

### Problema: Eventos não aparecem após codegen
**Solução:**
```bash
yarn config:fix
yarn validate
yarn dev
```

### Problema: startBlock incorreto
**Solução:**
O script de correção automaticamente ajusta para `startBlock: 15`

### Problema: Endereços incorretos
**Solução:**
O script garante que todos os contratos usem o mesmo endereço do Diamond

### Problema: Configuração completamente quebrada
**Solução:**
```bash
yarn config:restore
```

## Manutenção

### Atualizando o Template
Se precisar atualizar a configuração base:

1. Edite `config-template.ts`
2. Execute `yarn config:restore`
3. Teste todas as funcionalidades
4. Faça commit das mudanças

### Monitoramento
- Sempre verifique os logs após executar codegen
- Use `yarn validate` regularmente
- Mantenha backups atualizados

## Configurações Críticas a Monitorar

```typescript
// Essas configurações NUNCA devem mudar:
const DIAMOND_ADDRESS = "0x82dc47734901ee7d4f4232f398752cb9dd5daccc";
const START_BLOCK = 15;

// Todos os contratos devem usar:
address: DIAMOND_ADDRESS,
startBlock: START_BLOCK,
```

Com essa implementação, o sistema é resiliente a mudanças no codegen e problemas de configuração são automaticamente detectados e corrigidos.