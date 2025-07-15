# NFT Purchase System - Guia Completo

## Visão Geral

O sistema de compra de NFT do Scrum Poker permite que os usuários adquiram badges (NFTs) que representam sua participação no sistema. Estes NFTs são necessários para participar de cerimônias e votações.

## Funcionalidades Implementadas

### 1. Compra de NFT (`purchaseNFT`)

**Descrição**: Permite a compra de um NFT (badge) mediante pagamento em ETH equivalente a 1 dólar.

**Parâmetros**:
- `_userName`: Nome do usuário (string)
- `_externalURI`: URI para metadados externos, como imagem/avatar (string)

**Valor**: Deve ser enviado exatamente o valor definido em `exchangeRate`

**Exemplo de uso**:
```solidity
// Comprar NFT
nftFacet.purchaseNFT{value: exchangeRate}("João Silva", "ipfs://QmHash123");
```

**Validações**:
- ✅ Valor enviado deve ser exato (`exchangeRate`)
- ✅ Usuário não pode já possuir um NFT
- ✅ Cotação não pode estar desatualizada (>24h)
- ✅ Contrato não pode estar pausado

**Eventos emitidos**:
- `NFTPurchased(address buyer, uint256 tokenId, uint256 amountPaid)`

### 2. Reembolso de NFT (`refundNFT`)

**Descrição**: Permite devolver o NFT e receber reembolso quando o contrato está pausado.

**Condições**:
- ✅ Contrato deve estar pausado
- ✅ Usuário deve possuir um NFT
- ✅ Usuário deve ser o dono do NFT

**Exemplo de uso**:
```solidity
// Reembolsar NFT (apenas quando pausado)
nftFacet.refundNFT();
```

**Eventos emitidos**:
- `NFTRefunded(address buyer, uint256 tokenId, uint256 amountRefunded)`

### 3. Retirada de Fundos (`withdrawFunds`)

**Descrição**: Permite ao administrador retirar os fundos acumulados das vendas.

**Permissões**: Apenas `ADMIN_ROLE`

**Exemplo de uso**:
```solidity
// Retirar fundos (apenas admin)
nftFacet.withdrawFunds();
```

**Eventos emitidos**:
- `FundsWithdrawn(address owner, uint256 amount)`

### 4. Consulta de Dados do Badge (`getBadgeData`)

**Descrição**: Obtém informações completas do badge de um usuário.

**Parâmetros**:
- `tokenId`: ID do token a ser consultado

**Retorno**:
- `userName`: Nome do usuário
- `userAddress`: Endereço do usuário
- `ceremoniesParticipated`: Número de cerimônias participadas
- `votesCast`: Número de votos realizados
- `sprintResults`: Array com resultados dos sprints
- `externalURI`: URI externa para metadados

**Exemplo de uso**:
```solidity
(
    string memory userName,
    address userAddress,
    uint256 ceremoniesParticipated,
    uint256 votesCast,
    ScrumPokerStorage.SprintResult[] memory sprintResults,
    string memory externalURI
) = nftFacet.getBadgeData(tokenId);
```

### 5. Consulta de Token do Usuário (`getUserToken`)

**Descrição**: Obtém o ID do token de um usuário específico.

**Parâmetros**:
- `user`: Endereço do usuário

**Retorno**: `uint256` - ID do token (0 se não possuir)

**Exemplo de uso**:
```solidity
uint256 tokenId = nftFacet.getUserToken(userAddress);
if (tokenId == 0) {
    // Usuário não possui NFT
}
```

### 6. Verificação de Vesting (`isVested`)

**Descrição**: Verifica se o período de vesting do usuário já passou.

**Parâmetros**:
- `user`: Endereço do usuário

**Retorno**: `bool` - true se o vesting passou

**Exemplo de uso**:
```solidity
bool canVote = nftFacet.isVested(userAddress);
```

## Fluxo Completo de Compra

### 1. Pré-requisitos
- Usuário deve ter ETH suficiente
- Cotação deve estar atualizada (< 24h)
- Contrato não deve estar pausado
- Usuário não deve já possuir um NFT

### 2. Processo de Compra
```javascript
// Frontend - Exemplo em JavaScript/TypeScript
const exchangeRate = await contract.read.exchangeRate();
const lastUpdate = await contract.read.lastExchangeRateUpdate();

// Verificar se cotação está atualizada
const now = Math.floor(Date.now() / 1000);
if (now - lastUpdate > 86400) { // 24 horas
    alert("Cotação desatualizada. Aguarde atualização.");
    return;
}

// Verificar se usuário já possui NFT
const existingToken = await contract.read.getUserToken([userAddress]);
if (existingToken !== 0n) {
    alert("Usuário já possui um NFT.");
    return;
}

// Realizar compra
const hash = await contract.write.purchaseNFT(
    ["Nome do Usuário", "ipfs://metadata-uri"],
    { value: exchangeRate }
);
```

### 3. Pós-compra
- NFT é mintado com ID sequencial (começando em 1)
- Usuário se torna dono do NFT
- Período de vesting inicia
- Fundos ficam no contrato para retirada posterior

## Configurações Importantes

### Variáveis de Estado
- `exchangeRate`: Valor em wei equivalente a 1 dólar
- `lastExchangeRateUpdate`: Timestamp da última atualização
- `vestingPeriod`: Período de vesting em segundos
- `nextTokenId`: Próximo ID de token a ser mintado
- `paused`: Flag de pausa do contrato

### Roles de Acesso
- `ADMIN_ROLE`: Pode retirar fundos e atualizar badges
- `PRICE_UPDATER_ROLE`: Pode atualizar cotação

## Tratamento de Erros

### Erros Customizados
- `IncorrectPaymentAmount()`: Valor enviado incorreto
- `NFTAlreadyPurchased()`: Usuário já possui NFT
- `WithdrawalFailed()`: Falha na transferência de fundos
- `NotPaused()`: Operação requer contrato pausado
- `NoNFT()`: Usuário não possui NFT
- `NotAuthorized()`: Sem permissão para operação

### Mensagens de Require
- `"NFTFacet: pausado"`: Contrato está pausado
- `"NFTFacet: price quote outdated"`: Cotação desatualizada
- `"NFTFacet: not owner"`: Não é dono do NFT

## Segurança

### Proteções Implementadas
- ✅ ReentrancyGuard em todas as funções de transferência
- ✅ Padrão de retirada (withdrawal pattern)
- ✅ Verificação de ownership
- ✅ Controle de acesso baseado em roles
- ✅ Validação de valores e parâmetros
- ✅ Verificação de estado do contrato

### Considerações de Gas
- Compra de NFT: ~150,000 gas
- Reembolso: ~80,000 gas
- Retirada de fundos: ~50,000 gas
- Consultas (view): ~30,000 gas

## Integração com Frontend

### Eventos para Escuta
```javascript
// Escutar compras de NFT
contract.watchEvent.NFTPurchased({
    onLogs: (logs) => {
        logs.forEach(log => {
            console.log(`NFT ${log.args.tokenId} comprado por ${log.args.buyer}`);
        });
    }
});

// Escutar reembolsos
contract.watchEvent.NFTRefunded({
    onLogs: (logs) => {
        logs.forEach(log => {
            console.log(`NFT ${log.args.tokenId} reembolsado para ${log.args.buyer}`);
        });
    }
});
```

### Verificações Recomendadas
```javascript
// Antes de permitir compra
async function canPurchaseNFT(userAddress) {
    const hasNFT = await contract.read.getUserToken([userAddress]) !== 0n;
    const isPaused = await contract.read.paused();
    const exchangeRate = await contract.read.exchangeRate();
    const lastUpdate = await contract.read.lastExchangeRateUpdate();
    const isQuoteRecent = (Date.now() / 1000) - lastUpdate < 86400;
    
    return !hasNFT && !isPaused && isQuoteRecent;
}
```

## Próximos Passos

Para completar a integração, considere implementar:

1. **Interface de usuário** para compra de NFT
2. **Visualização de badges** com metadados
3. **Histórico de transações** do usuário
4. **Notificações** para eventos importantes
5. **Integração com IPFS** para metadados
6. **Sistema de avatares** personalizados