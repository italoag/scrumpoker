# ScrumPoker - Implementação Diamond Protocol

Este projeto implementa o contrato ScrumPoker utilizando o padrão Diamond Protocol (EIP-2535) com a biblioteca Solarity 3.1. O padrão Diamond permite que o contrato seja modular, atualizável e mais eficiente em termos de tamanho e gerenciamento.

## Estrutura do Projeto

### Contratos Principais

- **ScrumPokerDiamond**: Contrato principal que implementa o padrão Diamond e atua como proxy para as facetas.
- **ScrumPokerStorage**: Biblioteca que define o armazenamento compartilhado entre todas as facetas.
- **DiamondInit**: Contrato de inicialização para configurar todas as facetas em uma única transação.

### Facetas

O contrato foi dividido em facetas especializadas:

1. **AdminFacet**: Gerencia configurações administrativas, como taxa de câmbio, pausa/despause e controle de acesso.
2. **NFTFacet**: Implementa a funcionalidade de NFT (badges), incluindo compra e gerenciamento de metadados.
3. **CeremonyFacet**: Gerencia cerimônias (sprints), solicitações de entrada e aprovação de participantes.
4. **VotingFacet**: Implementa votações gerais, votações de funcionalidades e atualização dos badges com resultados.

## Melhorias Implementadas

1. **Padrão de Retirada**: Os fundos são mantidos no contrato e podem ser retirados pelo owner, em vez de transferidos automaticamente.
2. **Controle de Acesso Granular**: Implementação de controle de acesso baseado em papéis (RBAC).
3. **Mecanismo de Pausa**: Permite pausar o contrato em caso de emergência.
4. **Integração com Oráculo de Preços**: Suporte para atualização da taxa de câmbio via oráculo.

## Como Implantar

O contrato `ScrumPokerDeployer` facilita a implantação do Diamond e suas facetas:

```solidity
ScrumPokerDeployer deployer = new ScrumPokerDeployer();
address diamond = deployer.deploy(
    ownerAddress,
    initialExchangeRate,
    vestingPeriod
);
```

## Como Usar

### Administração

```solidity
// Atualizar taxa de câmbio
AdminFacet(diamondAddress).updateExchangeRate(newRate);

// Pausar o contrato
AdminFacet(diamondAddress).pause();

// Despausar o contrato
AdminFacet(diamondAddress).unpause();

// Conceder papel
AdminFacet(diamondAddress).grantRole(SCRUM_MASTER_ROLE, address);
```

### NFT (Badges)

```solidity
// Comprar NFT
NFTFacet(diamondAddress).purchaseNFT{value: exchangeRate}("Nome", "URI");

// Retirar fundos (apenas admin)
NFTFacet(diamondAddress).withdrawFunds();

// Obter dados do badge
NFTFacet(diamondAddress).getBadgeData(tokenId);
```

### Cerimônias

```solidity
// Iniciar cerimônia
string memory code = CeremonyFacet(diamondAddress).startCeremony(sprintNumber);

// Solicitar entrada
CeremonyFacet(diamondAddress).requestCeremonyEntry(code);

// Aprovar entrada
CeremonyFacet(diamondAddress).approveEntry(code, participantAddress);

// Concluir cerimônia
CeremonyFacet(diamondAddress).concludeCeremony(code);
```

### Votações

```solidity
// Votar na cerimônia
VotingFacet(diamondAddress).vote(code, voteValue);

// Abrir votação de funcionalidade
VotingFacet(diamondAddress).openFunctionalityVote(code, functionalityCode);

// Votar em funcionalidade
VotingFacet(diamondAddress).voteFunctionality(code, sessionIndex, voteValue);

// Atualizar badges com resultados
VotingFacet(diamondAddress).updateBadges(code);
```

## Segurança

O contrato implementa várias medidas de segurança:

- Proteção contra reentrância em todas as funções críticas
- Padrão de retirada para transferências de fundos
- Controle de acesso baseado em papéis
- Mecanismo de pausa para emergências
- Verificações de estado em todas as operações críticas

## Upgrades

O padrão Diamond permite atualizações sem perda de dados:

1. Implantar novas facetas
2. Atualizar o Diamond para apontar para as novas facetas
3. Remover facetas obsoletas

Isso pode ser feito usando o método `diamondCut` do contrato Diamond.