## CR

Principais problemas encontrados (excluindo ScrumPoker.sol  e YourContract.sol)


Gravidade	Arquivo / Trecho	Descrição
Crítica	CeremonyFacet.startCeremony	string code = string(abi.encode("CEREMONY", uint2str(ds.ceremonyCounter))); – abi.encode devolve ABI-payload (offsets, tamanhos, padding). O resultado não é uma string UTF-8 válida e pode gerar códigos colididos ou ilegíveis. Use string(abi.encodePacked("CEREMONY", uint2str(...))) ou string.concat.
Crítica	ScrumPokerDiamond	Herda ReentrancyGuardUpgradeable mas nunca chama __ReentrancyGuard_init(). Qualquer função nonReentrant (ex.: withdrawEther) reverte ou fica desprotegida (depende do valor default do storage).
Alta	NFTFacet.purchaseNFT	Aceita pagamento mesmo se a cotação (exchangeRate) estiver desatualizada (apenas emite evento). Usuário mal-intencionado pode comprar NFT bem mais barato/caro.
Alta	AdminFacet.updateExchangeRate	Não valida newRate > 0; admin malicioso ou “price-updater” comprometido pode zerar ou definir valor irreal.
Alta	Loops não limitados	VotingFacet.updateBadges percorre todos os participantes e todas as sessões → pode estourar block gas e impedir conclusão do sprint.
Média	openFunctionalityVote	Permite abrir quantas sessões quiser para a mesma funcionalidade/sprint, sem checar duplicidade.
Média	RBAC caseiro	Mapeamento simples roles[role][addr]; não há renounceRole, nem onlyRole centralizado, nem eventos de revogação em todos os fluxos. Pode ficar difícil auditar.
Média	Oracle	priceOracle é gravado mas nunca utilizado. Não há função que faça pull de preço on-chain.
Média	Pausa global	_beforeFallback libera alguns seletores, mas não libera purchaseNFT, vote, etc. Em caso de pausa prolongada usuários ficam travados sem possibilidade de saque do valor pago pela NFT.
Baixa	vote/voteFunctionality	Não existem limites de voto (p.ex. 0 ≤ valor ≤ N). Participante pode enviar número arbitrariamente grande.
Baixa	Naming / Storage	Muitos mapeamentos “legados” mantidos para compatibilidade; ocupam gas e complexificam lógica.
Info	Falta visibilidade	Não há funções para consultar resultados consolidados de votos de funcionalidades nem placar de pontos total do sprint.
Info	Test coverage	Não há scripts automatizados para testar migração de formato legado → otimizado.
Funcionalidades ausentes / gargalos para o Scrum Poker on-chain
Consulta pública de resultados (total de pontos por participante e por funcionalidade).
“Reveal” / antifraude: hoje o voto é gravado diretamente; líderes podem ver votos durante a sessão.
Governança de price updater: qualquer admin pode alterar drasticamente a cotação.
Migração de storage legado nunca é disparada automaticamente → dados antigos ficam inacessíveis até que alguém chame migrateCeremony.
Falta uma forma de claim de badge ponto-a-ponto (self-service) para evitar laços grandes.
Falta mecanismo de upgrade seguro do Diamond (pausar->diamondCut->unpause).
Não há unit tests para reentrância, overflows de loop, nem teste de inicialização múltipla.
Recomendações de melhoria (técnicas)
Consertar geração de ceremonyCode (abi.encodePacked).
Adicionar __ReentrancyGuard_init() no construtor do Diamond OU remover o modificador nonReentrant dali e usar só nas facetas.
Em purchaseNFT, exigir block.timestamp <= lastExchangeRateUpdate + GRACE_PERIOD.
Validar newRate > 0 e, opcionalmente, absDiff(old,new) <= x%.
Limitar tamanho de laços:
• updateBadges → dividir em lotes (ex.: função updateBadgeChunk(uint256 from, uint256 to)).
• Mesma lógica para migrar legacy sessions.
Adicionar require(!session.active) antes de abrir nova sessão com mesmo código.
Substituir RBAC manual por AccessControlEnumerable (mantendo hash no storage para compatibilidade).
Implementar função getSprintResults(string code) que devolve agregados.
Criar módulo Oracle: pull Chainlink USD/ETH e atualizar exchangeRate automaticamente.
Acrescentar renounceRole, transferAdmin, logs extras.
Roadmap sugerido
Fase	Entregas
0.1 – Fixes	• Correções críticas acima • Scripts de hard-fork test/foundry para cobrir fluxo completo
0.2 – Resultados & UX	• Função de leitura de placar • Front-end para exibir votos em tempo real (com cache fora da cadeia)
0.3 – Escalabilidade	• Batch update de badges • Paginação em eventos • Gas-optimization review
0.4 – Segurança	• Commit-reveal de votos • ZKP-vote (opcional) • Time-lock/Timelapse p/ troca de exchangeRate
0.5 – Tokenomics	• Emissão de token utilitário (recompensas de participação) • Staking para privilégios de Scrum Master
0.6 – Governança	• DAO para definir vestingPeriod, maxContribution, cotação-limite
0.7 – Cross-Chain	• Portar badges como ERC-721 bridgeable • Suporte a L2 (Arbitrum / Base)
1.0 GA	• Auditoria externa • Certificação & Bug-Bounty
Siga corrigindo os pontos críticos antes de pôr o contrato em produção. Estou à disposição para detalhar qualquer correção ou escrever testes específicos.