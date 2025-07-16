# FEATURE PLANNING - Sistema ScrumPoker

## Visão Geral

Este documento descreve o plano para expandir as funcionalidades do sistema de Scrumpoker para incluir todos os ritos de um ciclo completo de Scrum, transformando-o de um sistema focado apenas em Planning Poker para uma plataforma completa de gestão de cerimônias Scrum.

## Estado Atual

### ✅ Funcionalidades Implementadas:
- Sistema de Planning Poker com commit-reveal
- Roles básicas (ADMIN, SCRUM_MASTER, PRICE_UPDATER)
- NFTs como recompensas
- Vesting básico
- Arquitetura Diamond para upgradabilidade

### ❌ Funcionalidades Ausentes:
- Roles específicas do Scrum (Product Owner, Developer)
- Diferentes tipos de cerimônias
- Vesting diferenciado por papel
- **Sistema de rejeição de solicitações** (atualmente só aprovação)
- Escalas de estimação customizáveis
- Métricas e relatórios

## Roadmap de Implementação

### FASE 1: Estrutura de Roles (Sprint 1-2)

#### 1.1 Novas Roles
**Prioridade:** Alta  
**Esforço:** 13 pontos  
**Arquivos afetados:** `ScrumPokerStorage.sol`

- [ ] Adicionar novas constantes de roles:
  ```solidity
  bytes32 constant PRODUCT_OWNER_ROLE = keccak256("PRODUCT_OWNER_ROLE");
  bytes32 constant DEVELOPER_ROLE = keccak256("DEVELOPER_ROLE");
  bytes32 constant TEAM_MEMBER_ROLE = keccak256("TEAM_MEMBER_ROLE");
  ```

#### 1.2 Estrutura de Vesting Diferenciado
**Prioridade:** Alta  
**Esforço:** 8 pontos  
**Arquivos afetados:** `ScrumPokerStorage.sol`, `AdminFacet.sol`

- [ ] Criar estrutura `RoleVesting`:
  ```solidity
  struct RoleVesting {
      uint256 productOwnerVesting;
      uint256 scrumMasterVesting;
      uint256 developerVesting;
      uint256 teamMemberVesting;
  }
  ```

- [ ] Atualizar `DiamondStorage` para incluir `RoleVesting roleVesting`
- [ ] Implementar função `updateRoleVesting()` no `AdminFacet`
- [ ] Modificar lógica de vesting em `CeremonyFacet.approveEntry()`

#### 1.3 Sistema de Rejeição de Solicitações
**Prioridade:** Alta  
**Esforço:** 13 pontos  
**Arquivos afetados:** `CeremonyFacet.sol`, `ScrumPokerStorage.sol`

- [ ] Adicionar controle de rejeição no storage:
  ```solidity
  // Controle de rejeição: cerimônia => (usuário => bool)
  mapping(bytes32 => mapping(address => bool)) ceremonyRejected;
  // Controle de bloqueio: cerimônia => (usuário => bool) 
  mapping(bytes32 => mapping(address => bool)) ceremonyBlocked;
  ```

- [ ] Implementar função `rejectCeremonyEntry()`:
  ```solidity
  function rejectCeremonyEntry(string memory _code, address _participant, string memory _reason) external;
  ```

- [ ] Implementar função `blockParticipant()`:
  ```solidity
  function blockParticipant(string memory _code, address _participant) external;
  ```

- [ ] Implementar função `unblockParticipant()`:
  ```solidity
  function unblockParticipant(string memory _code, address _participant) external;
  ```

- [ ] Adicionar validações em `requestCeremonyEntry()` para verificar se o usuário foi rejeitado/bloqueado
- [ ] Permitir nova solicitação após rejeição (com cooldown opcional)

#### 1.4 Eventos para Roles e Rejeições
**Prioridade:** Média  
**Esforço:** 8 pontos

- [ ] Adicionar eventos específicos:
  ```solidity
  event ProductOwnerAction(address indexed productOwner, string action, string ceremonyCode);
  event DeveloperParticipation(address indexed developer, string ceremonyCode);
  event RoleVestingUpdated(bytes32 indexed role, uint256 oldVesting, uint256 newVesting);
  event CeremonyEntryRejected(string ceremonyCode, address indexed participant, address indexed rejector, string reason);
  event ParticipantBlocked(string ceremonyCode, address indexed participant, address indexed blocker);
  event ParticipantUnblocked(string ceremonyCode, address indexed participant, address indexed unblocker);
  ```

### FASE 2: Tipos de Cerimônia (Sprint 3-4)

#### 2.1 Enum de Tipos de Cerimônia
**Prioridade:** Alta  
**Esforço:** 21 pontos  
**Arquivos afetados:** `ScrumPokerStorage.sol`, `CeremonyFacet.sol`

- [ ] Criar enum `CeremonyType`:
  ```solidity
  enum CeremonyType {
      PLANNING_POKER,
      SPRINT_PLANNING,
      DAILY_STANDUP,
      SPRINT_REVIEW,
      SPRINT_RETROSPECTIVE,
      BACKLOG_REFINEMENT
  }
  ```

- [ ] Atualizar struct `Ceremony` para incluir `CeremonyType ceremonyType`
- [ ] Modificar `startCeremony()` para aceitar tipo de cerimônia
- [ ] Implementar validações específicas por tipo de cerimônia

#### 2.2 Fluxos Específicos por Tipo
**Prioridade:** Alta  
**Esforço:** 34 pontos

- [ ] **Daily Standup**: Implementar funcionalidade para updates diários
- [ ] **Sprint Review**: Funcionalidade para apresentação de incrementos
- [ ] **Sprint Retrospective**: Sistema de feedback e melhorias
- [ ] **Backlog Refinement**: Ferramenta para refinamento de itens

#### 2.3 Configurações por Tipo de Cerimônia
**Prioridade:** Média  
**Esforço:** 13 pontos

- [ ] Criar struct `CeremonyConfig`:
  ```solidity
  struct CeremonyConfig {
      uint256 maxParticipants;
      uint256 minParticipants;
      uint256 maxDuration;
      bool requiresProductOwner;
      bool allowsVoting;
  }
  ```

### FASE 3: Funcionalidades do Product Owner (Sprint 5-6)

#### 3.1 Definição de Critérios de Aceitação
**Prioridade:** Alta  
**Esforço:** 21 pontos  
**Arquivos afetados:** `CeremonyFacet.sol`, `ScrumPokerStorage.sol`

- [ ] Criar struct `AcceptanceCriteria`:
  ```solidity
  struct AcceptanceCriteria {
      string functionalityCode;
      string[] criteria;
      bool approved;
      address productOwner;
  }
  ```

- [ ] Implementar função `defineAcceptanceCriteria()`
- [ ] Função `approveAcceptanceCriteria()` exclusiva para Product Owner
- [ ] Validação de critérios antes da conclusão da cerimônia

#### 3.2 Priorização de Backlog
**Prioridade:** Alta  
**Esforço:** 13 pontos

- [ ] Implementar função `prioritizeBacklogItem()`
- [ ] Sistema de ordenação de funcionalidades
- [ ] Eventos para mudanças de prioridade

#### 3.3 Veto de Estimativas
**Prioridade:** Média  
**Esforço:** 8 pontos

- [ ] Implementar função `vetoEstimate()`
- [ ] Lógica para reabrir votação após veto
- [ ] Limite de vetos por cerimônia

### FASE 4: Escalas de Estimação (Sprint 7)

#### 4.1 Escalas Predefinidas
**Prioridade:** Média  
**Esforço:** 13 pontos  
**Arquivos afetados:** `ScrumPokerStorage.sol`, `VotingFacet.sol`

- [ ] Criar enum `EstimationScale`:
  ```solidity
  enum EstimationScale {
      FIBONACCI,    // 1, 2, 3, 5, 8, 13, 21, 34, 55, 89
      T_SHIRT,      // XS, S, M, L, XL, XXL
      POWERS_OF_2,  // 1, 2, 4, 8, 16, 32, 64
      CUSTOM
  }
  ```

- [ ] Implementar validação de votos baseada na escala escolhida
- [ ] Função `setCeremonyScale()` para configurar escala por cerimônia

#### 4.2 Escalas Customizáveis
**Prioridade:** Baixa  
**Esforço:** 8 pontos

- [ ] Struct `CustomScale` para escalas personalizadas
- [ ] Função `createCustomScale()` para admins
- [ ] Validação de escalas customizadas

### FASE 5: Métricas e Relatórios (Sprint 8-9)

#### 5.1 Métricas de Participação
**Prioridade:** Média  
**Esforço:** 21 pontos  
**Arquivos afetados:** `VotingFacet.sol`, `NFTFacet.sol`

- [ ] Implementar função `getParticipationMetrics()`:
  ```solidity
  struct ParticipationMetrics {
      uint256 totalCeremonies;
      uint256 participationsByRole;
      uint256 averageVotes;
      uint256 consensusRate;
  }
  ```

- [ ] Função `getRoleParticipation()` para métricas por papel
- [ ] Histórico de participação por usuário

#### 5.2 Precisão de Estimativas
**Prioridade:** Média  
**Esforço:** 13 pontos

- [ ] Implementar função `recordActualEffort()`
- [ ] Cálculo de precisão de estimativas
- [ ] Relatório de melhoria de precisão ao longo do tempo

#### 5.3 Velocity e Consenso
**Prioridade:** Baixa  
**Esforço:** 8 pontos

- [ ] Função `calculateTeamVelocity()`
- [ ] Análise de consenso em votações
- [ ] Relatórios de tendências

### FASE 6: Otimizações e Melhorias (Sprint 10)

#### 6.1 Otimizações de Gas
**Prioridade:** Alta  
**Esforço:** 13 pontos

- [ ] Otimizar loops em `updateBadgesRange()`
- [ ] Usar assembly para operações críticas
- [ ] Implementar batch operations

#### 6.2 Melhorias na UX
**Prioridade:** Média  
**Esforço:** 8 pontos

- [ ] Implementar função `getCeremonyStatus()`
- [ ] Função `getUpcomingCeremonies()`
- [ ] Melhorar eventos para UI

#### 6.3 Segurança
**Prioridade:** Alta  
**Esforço:** 5 pontos

- [ ] Auditoria de segurança completa
- [ ] Implementar rate limiting
- [ ] Validações adicionais

## Estratégia de Implementação

### 1. Metodologia
- **Sprints de 2 semanas**
- **Desenvolvimento incremental** com deploys frequentes
- **Test-Driven Development (TDD)**
- **Code Reviews** obrigatórias

### 2. Testes
- **Cobertura mínima:** 90%
- **Testes unitários** para cada função
- **Testes de integração** para fluxos completos
- **Testes de gas** para otimizações

### 3. Documentação
- **Atualização contínua** do README
- **Documentação técnica** para cada nova funcionalidade
- **Guias de usuário** para diferentes roles

### 4. Migração
- **Versionamento de storage** para upgrades suaves
- **Scripts de migração** para dados existentes
- **Backup e rollback** procedures

## Riscos e Mitigações

### Riscos Técnicos
1. **Complexidade de Roles**
   - *Risco:* Bugs de segurança
   - *Mitigação:* Testes extensivos de permissões

2. **Layout de Storage**
   - *Risco:* Quebra de compatibilidade
   - *Mitigação:* Versionamento rigoroso

3. **Eficiência de Gas**
   - *Risco:* Transações caras
   - *Mitigação:* Otimizações e batch operations

### Riscos de Negócio
1. **Complexidade de UX**
   - *Risco:* Usuários confusos
   - *Mitigação:* UI intuitiva e documentação

2. **Adoção**
   - *Risco:* Resistência à mudança
   - *Mitigação:* Rollout gradual e treinamento

## Métricas de Sucesso

### Técnicas
- [ ] Cobertura de testes ≥ 90%
- [ ] Gas por transação ≤ 200k
- [ ] Tempo de resposta ≤ 2s
- [ ] Zero vulnerabilidades críticas

### Negócio
- [ ] Suporte completo aos 5 tipos de cerimônia
- [ ] 3 roles funcionais implementadas
- [ ] Redução de 50% no tempo de cerimônias
- [ ] Aumento de 30% na participação

## Cronograma

| Sprint | Duração | Funcionalidades | Pontos |
|--------|---------|----------------|--------|
| 1-2    | 4 sem   | Estrutura de Roles + Sistema de Rejeição | 42 |
| 3-4    | 4 sem   | Tipos de Cerimônia | 68 |
| 5-6    | 4 sem   | Funcionalidades PO | 42 |
| 7      | 2 sem   | Escalas Estimação | 21 |
| 8-9    | 4 sem   | Métricas/Relatórios | 42 |
| 10     | 2 sem   | Otimizações | 26 |

**Total:** 241 pontos em 20 semanas (~5 meses)

### Detalhamento Sprint 1-2 (Sistema de Rejeição):
- **1.1 Novas Roles**: 13 pontos
- **1.2 Vesting Diferenciado**: 8 pontos
- **1.3 Sistema de Rejeição**: 13 pontos ⭐ **NOVA FUNCIONALIDADE**
- **1.4 Eventos**: 8 pontos
- **Subtotal**: 42 pontos

## Funcionalidades de Rejeição - Detalhamento

### Problema Atual
Atualmente, o sistema apenas permite que o Scrum Master **aprove** solicitações de participação em cerimônias. Não há mecanismo para:
- Rejeitar solicitações inadequadas
- Bloquear participantes problemáticos
- Fornecer feedback sobre por que uma solicitação foi rejeitada

### Solução Proposta

#### 1. Fluxo de Rejeição Simples
```solidity
// Usuário solicita participação
requestCeremonyEntry("CEREMONY1") 

// Scrum Master pode aprovar OU rejeitar
approveEntry("CEREMONY1", participant) // Atual
rejectCeremonyEntry("CEREMONY1", participant, "Não possui NFT adequado") // NOVO
```

#### 2. Sistema de Bloqueio
```solidity
// Para casos mais sérios, bloquear participante
blockParticipant("CEREMONY1", participant)

// Participante bloqueado não pode mais solicitar entrada
// Até ser desbloqueado
unblockParticipant("CEREMONY1", participant)
```

#### 3. Validações Adicionais
- Verificar se usuário foi rejeitado antes
- Implementar cooldown opcional após rejeição
- Impedir spam de solicitações

#### 4. Eventos para Transparência
```solidity
event CeremonyEntryRejected(string ceremonyCode, address participant, address rejector, string reason);
event ParticipantBlocked(string ceremonyCode, address participant, address blocker);
event ParticipantUnblocked(string ceremonyCode, address participant, address unblocker);
```

### Casos de Uso

1. **Participante sem NFT adequado**: Rejeição simples com orientação
2. **Participante disruptivo**: Bloqueio temporário
3. **Capacidade limitada**: Rejeição por limite de participantes
4. **Papel inadequado**: Rejeição por não ter role necessária

### Benefícios

- ✅ **Controle de qualidade**: Scrum Master pode manter cerimônias focadas
- ✅ **Feedback claro**: Participantes sabem por que foram rejeitados
- ✅ **Prevenção de spam**: Evita solicitações inadequadas repetitivas
- ✅ **Transparência**: Todos os eventos são registrados na blockchain
- ✅ **Flexibilidade**: Permite diferentes níveis de restrição

### Implementação Técnica

#### Storage Additions:
```solidity
// No DiamondStorage
mapping(bytes32 => mapping(address => bool)) ceremonyRejected;
mapping(bytes32 => mapping(address => bool)) ceremonyBlocked;
mapping(bytes32 => mapping(address => string)) rejectionReasons;
mapping(bytes32 => mapping(address => uint256)) rejectionTimestamp;
```

#### Validações:
```solidity
function requestCeremonyEntry(string memory _code) external {
    bytes32 codeHash = ScrumPokerStorage.getCeremonyCodeHash(_code);
    
    // Verificar se foi bloqueado
    require(!ds.ceremonyBlocked[codeHash][msg.sender], "Participante bloqueado");
    
    // Verificar cooldown após rejeição (se implementado)
    if (ds.ceremonyRejected[codeHash][msg.sender]) {
        uint256 cooldownPeriod = 1 hours; // Configurável
        require(
            block.timestamp >= ds.rejectionTimestamp[codeHash][msg.sender] + cooldownPeriod,
            "Cooldown ativo após rejeição"
        );
    }
    
    // Resto da lógica atual...
}
```

---

*Este documento será atualizado conforme o progresso do desenvolvimento e feedback da equipe.*
