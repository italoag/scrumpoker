# Guia Completo: Inicialização de Cerimônias no ScrumPoker

## Visão Geral

O ScrumPoker utiliza um sistema de geração automática de códigos únicos para cerimônias. O método `startCeremony` **retorna automaticamente** o código gerado, não sendo necessário configuração adicional.

## Como Funciona a Geração de Códigos

### 1. Implementação do `startCeremony`

```solidity
function startCeremony(uint256 _sprintNumber) external returns (string memory) {
    // Gera código único baseado no contador interno
    string memory code = string(abi.encodePacked("CEREMONY", uint2str(ds.ceremonyCounter)));
    
    // Registra o código no sistema
    bytes32 codeHash = ScrumPokerStorage.registerCeremonyCode(code);
    
    // Incrementa contador para próxima cerimônia
    ds.ceremonyCounter++;
    
    // Retorna o código gerado
    return code;
}
```

### 2. Formato dos Códigos Gerados

- **Padrão**: `CEREMONY{número}`
- **Exemplos**: 
  - Primeira cerimônia: `CEREMONY1`
  - Segunda cerimônia: `CEREMONY2`
  - Terceira cerimônia: `CEREMONY3`

### 3. Sistema de Armazenamento Otimizado

O sistema utiliza um **dual storage** para máxima eficiência:

```solidity
// Armazenamento otimizado (bytes32 hash)
mapping(bytes32 => Ceremony) ceremoniesByHash;
mapping(bytes32 => bool) ceremonyExists;

// Compatibilidade legada (string)
mapping(string => bytes32) ceremonyCodeToHash;
```

## Fluxo Completo de Uso

### Passo 1: Iniciar Cerimônia

```javascript
// Chama o contrato para iniciar uma nova cerimônia
const sprintNumber = 1;
const transaction = await contract.startCeremony(sprintNumber);
const receipt = await transaction.wait();

// O código é retornado automaticamente pela função
const ceremonyCode = await contract.startCeremony.staticCall(sprintNumber);
console.log("Código da cerimônia:", ceremonyCode); // "CEREMONY1"
```

### Passo 2: Verificar Existência da Cerimônia

```javascript
// Verifica se a cerimônia existe
const exists = await contract.ceremonyExists(ceremonyCode);
console.log("Cerimônia existe:", exists); // true
```

### Passo 3: Obter Detalhes da Cerimônia

```javascript
// Obtém todos os detalhes da cerimônia
const ceremony = await contract.getCeremony(ceremonyCode);
console.log({
    code: ceremony.code,
    sprintNumber: ceremony.sprintNumber,
    startTime: ceremony.startTime,
    scrumMaster: ceremony.scrumMaster,
    active: ceremony.active,
    participants: ceremony.participants
});
```

### Passo 4: Solicitar Entrada na Cerimônia

```javascript
// Participante solicita entrada
await contract.requestCeremonyEntry(ceremonyCode);

// Scrum Master aprova entrada
await contract.approveEntry(ceremonyCode, participantAddress);
```

## Exemplo Prático Completo

```javascript
// 1. Inicializar cerimônia (como Scrum Master)
const sprintNumber = 1;
const tx = await scrumPokerContract.startCeremony(sprintNumber);
await tx.wait();

// 2. Capturar o código do evento emitido
const filter = scrumPokerContract.filters.CeremonyStarted();
const events = await scrumPokerContract.queryFilter(filter, tx.blockNumber);
const ceremonyCode = events[0].args.ceremonyCode;

console.log("Código da cerimônia criada:", ceremonyCode);

// 3. Verificar se a cerimônia foi criada corretamente
const exists = await scrumPokerContract.ceremonyExists(ceremonyCode);
console.log("Cerimônia existe:", exists);

// 4. Obter detalhes completos
const ceremony = await scrumPokerContract.getCeremony(ceremonyCode);
console.log("Detalhes da cerimônia:", {
    code: ceremony.code,
    sprintNumber: ceremony.sprintNumber.toString(),
    startTime: new Date(ceremony.startTime.toNumber() * 1000),
    scrumMaster: ceremony.scrumMaster,
    active: ceremony.active,
    participants: ceremony.participants
});

// 5. Fluxo de participação
// Participante solicita entrada
await scrumPokerContract.connect(participant).requestCeremonyEntry(ceremonyCode);

// Scrum Master aprova
await scrumPokerContract.connect(scrumMaster).approveEntry(ceremonyCode, participant.address);

// Verificar aprovação
const isApproved = await scrumPokerContract.isApproved(ceremonyCode, participant.address);
console.log("Participante aprovado:", isApproved);
```

## Eventos Importantes

### CeremonyStarted
```solidity
event CeremonyStarted(
    string ceremonyCode,
    uint256 sprintNumber,
    uint256 startTime,
    address indexed scrumMaster
);
```

### CeremonyEntryRequested
```solidity
event CeremonyEntryRequested(
    string ceremonyCode,
    address indexed participant
);
```

### EntryApproved
```solidity
event EntryApproved(
    string ceremonyCode,
    address indexed participant
);
```

## Métodos de Verificação

### Verificar Existência
```javascript
const exists = await contract.ceremonyExists("CEREMONY1");
```

### Verificar Solicitação de Entrada
```javascript
const hasRequested = await contract.hasRequestedEntry("CEREMONY1", userAddress);
```

### Verificar Aprovação
```javascript
const isApproved = await contract.isApproved("CEREMONY1", userAddress);
```

## Tratamento de Erros

### Erros Comuns

1. **CeremonyNotFound**: Código de cerimônia não existe
2. **NotAuthorized**: Usuário não tem permissão para a operação
3. **EntryAlreadyRequested**: Usuário já solicitou entrada
4. **NFTRequired**: Usuário precisa possuir um NFT para participar

### Exemplo de Tratamento

```javascript
try {
    await contract.requestCeremonyEntry(ceremonyCode);
} catch (error) {
    if (error.message.includes("CeremonyNotFound")) {
        console.error("Cerimônia não encontrada");
    } else if (error.message.includes("NFTRequired")) {
        console.error("Você precisa possuir um NFT para participar");
    } else if (error.message.includes("EntryAlreadyRequested")) {
        console.error("Você já solicitou entrada nesta cerimônia");
    }
}
```

## Integração com Frontend

### Hook React Exemplo

```javascript
import { useState, useEffect } from 'react';
import { useContract } from './useContract';

export function useCeremony(ceremonyCode) {
    const [ceremony, setCeremony] = useState(null);
    const [loading, setLoading] = useState(true);
    const contract = useContract();

    useEffect(() => {
        async function loadCeremony() {
            if (!ceremonyCode || !contract) return;
            
            try {
                const exists = await contract.ceremonyExists(ceremonyCode);
                if (exists) {
                    const ceremonyData = await contract.getCeremony(ceremonyCode);
                    setCeremony({
                        code: ceremonyData.code,
                        sprintNumber: ceremonyData.sprintNumber.toString(),
                        startTime: new Date(ceremonyData.startTime.toNumber() * 1000),
                        scrumMaster: ceremonyData.scrumMaster,
                        active: ceremonyData.active,
                        participants: ceremonyData.participants
                    });
                }
            } catch (error) {
                console.error("Erro ao carregar cerimônia:", error);
            } finally {
                setLoading(false);
            }
        }

        loadCeremony();
    }, [ceremonyCode, contract]);

    return { ceremony, loading };
}
```

## Conclusão

O sistema de inicialização de cerimônias no ScrumPoker é **totalmente automatizado**:

1. ✅ **Códigos são gerados automaticamente** pelo `startCeremony`
2. ✅ **Não há necessidade de configuração manual** de códigos
3. ✅ **Sistema otimizado** com dual storage para eficiência
4. ✅ **Eventos emitidos** para facilitar integração frontend
5. ✅ **Métodos de verificação** disponíveis para validação

O parâmetro `_code` nos métodos subsequentes deve usar o código **retornado** pelo `startCeremony`, garantindo compatibilidade total com o sistema.