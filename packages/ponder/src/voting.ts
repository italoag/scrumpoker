import { ponder } from "ponder:registry";
import { 
  functionalityVote, 
  functionalitySession,
  ceremonyStats 
} from "ponder:schema";

// Evento: FunctionalityVoteOpened
ponder.on("VotingFacet:FunctionalityVoteOpened", async ({ event, context }) => {
  const ceremonyCode = event.args.ceremonyCode;
  const sessionIndex = event.args.sessionIndex;
  const functionalityCode = event.args.functionalityCode;
  
  // Criar nova sessão de votação
  await context.db.insert(functionalitySession).values({
    id: `${ceremonyCode}-${sessionIndex}`,
    ceremonyCode: ceremonyCode,
    sessionIndex: sessionIndex,
    functionalityCode: functionalityCode,
    status: "opened",
    openedAt: Number(event.block.timestamp),
    blockNumber: event.block.number,
    transactionHash: event.transaction.hash,
  });
});

// Evento: FunctionalityVoteCommitted
ponder.on("VotingFacet:FunctionalityVoteCommitted", async ({ event, context }) => {
  const ceremonyCode = event.args.ceremonyCode;
  const sessionIndex = event.args.sessionIndex;
  const participant = event.args.participant;
  
  // Criar ou atualizar voto
  const voteId = `${ceremonyCode}-${sessionIndex}-${participant}`;
  
  await context.db.insert(functionalityVote).values({
    id: voteId,
    ceremonyCode: ceremonyCode,
    sessionIndex: sessionIndex,
    participant: participant,
    isCommitted: true,
    isRevealed: false,
    committedAt: Number(event.block.timestamp),
    blockNumber: event.block.number,
    transactionHash: event.transaction.hash,
  });
});

// Evento: FunctionalityVoteRevealed
ponder.on("VotingFacet:FunctionalityVoteRevealed", async ({ event, context }) => {
  const ceremonyCode = event.args.ceremonyCode;
  const sessionIndex = event.args.sessionIndex;
  const participant = event.args.participant;
  const voteValue = event.args.voteValue;
  
  const voteId = `${ceremonyCode}-${sessionIndex}-${participant}`;
  
  // Atualizar voto com o valor revelado
  await context.db.update(functionalityVote, { id: voteId }).set({
    voteValue: voteValue,
    isRevealed: true,
    revealedAt: Number(event.block.timestamp),
  });

  // Atualizar estatísticas
  const stats = await context.db.find(ceremonyStats, { id: "global" });
  if (stats) {
    await context.db.update(ceremonyStats, { id: "global" }).set({
      totalVotes: stats.totalVotes + 1n,
      lastUpdated: Number(event.block.timestamp),
    });
  }
});

// Evento: FunctionalityVoteCast (para votação direta sem commit/reveal)
ponder.on("VotingFacet:FunctionalityVoteCast", async ({ event, context }) => {
  const ceremonyCode = event.args.ceremonyCode;
  const sessionIndex = event.args.sessionIndex;
  const participant = event.args.participant;
  const voteValue = event.args.voteValue;
  
  const voteId = `${ceremonyCode}-${sessionIndex}-${participant}`;
  
  // Criar voto direto
  await context.db.insert(functionalityVote).values({
    id: voteId,
    ceremonyCode: ceremonyCode,
    sessionIndex: sessionIndex,
    participant: participant,
    voteValue: voteValue,
    isCommitted: true,
    isRevealed: true,
    committedAt: Number(event.block.timestamp),
    revealedAt: Number(event.block.timestamp),
    blockNumber: event.block.number,
    transactionHash: event.transaction.hash,
  });

  // Atualizar estatísticas
  const stats = await context.db.find(ceremonyStats, { id: "global" });
  if (stats) {
    await context.db.update(ceremonyStats, { id: "global" }).set({
      totalVotes: stats.totalVotes + 1n,
      lastUpdated: Number(event.block.timestamp),
    });
  }
});

// Evento: FunctionalityVoteClosed
ponder.on("VotingFacet:FunctionalityVoteClosed", async ({ event, context }) => {
  const ceremonyCode = event.args.ceremonyCode;
  const sessionIndex = event.args.sessionIndex;
  const closer = event.args.closer;
  
  // Atualizar sessão de votação
  await context.db.update(functionalitySession, { 
    id: `${ceremonyCode}-${sessionIndex}` 
  }).set({
    status: "closed",
    closedAt: Number(event.block.timestamp),
    closedBy: closer,
  });
});