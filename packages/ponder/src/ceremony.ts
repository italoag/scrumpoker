import { ponder } from "ponder:registry";
import { 
  ceremony, 
  ceremonyParticipant, 
  ceremonyStats 
} from "ponder:schema";

// Evento: CeremonyStarted - Criação real de cerimônia
ponder.on("CeremonyFacet:CeremonyStarted", async ({ event, context }) => {
  const ceremonyCode = event.args.ceremonyCode;
  const scrumMaster = event.args.scrumMaster;
  const sprintNumber = event.args.sprintNumber;
  const startTime = event.args.startTime;
  
  console.log(`Processing CeremonyStarted: ${ceremonyCode}`);
  
  // Verificar se a cerimônia já existe
  const existingCeremony = await context.db.find(ceremony, { id: ceremonyCode });
  
  if (!existingCeremony) {
    // Criar nova cerimônia
    await context.db.insert(ceremony).values({
      id: ceremonyCode,
      creator: scrumMaster,
      title: `Ceremony ${ceremonyCode}`,
      description: `Sprint ${sprintNumber} planning ceremony`,
      status: "started",
      createdAt: Number(startTime),
      startedAt: Number(startTime),
      blockNumber: event.block.number,
      transactionHash: event.transaction.hash,
    });

    console.log(`Created ceremony: ${ceremonyCode}`);

    // Atualizar estatísticas
    const stats = await context.db.find(ceremonyStats, { id: "global" });
    if (stats) {
      await context.db.update(ceremonyStats, { id: "global" }).set({
        totalCeremonies: stats.totalCeremonies + 1n,
        lastUpdated: Number(event.block.timestamp),
      });
    } else {
      await context.db.insert(ceremonyStats).values({
        id: "global",
        totalCeremonies: 1n,
        totalParticipants: 0n,
        totalVotes: 0n,
        lastUpdated: Number(event.block.timestamp),
      });
    }
  } else {
    // Atualizar cerimônia existente com dados do CeremonyStarted
    await context.db.update(ceremony, { id: ceremonyCode }).set({
      status: "started",
      startedAt: Number(startTime),
    });
    
    console.log(`Updated ceremony: ${ceremonyCode}`);
  }
});

// Evento: CeremonyEntryRequested - Gerenciamento de participantes
ponder.on("CeremonyFacet:CeremonyEntryRequested", async ({ event, context }) => {
  const ceremonyCode = event.args.ceremonyCode;
  const participant = event.args.participant;
  
  console.log(`Processing CeremonyEntryRequested: ${participant} for ${ceremonyCode}`);
  
  // Adicionar participante
  await context.db.insert(ceremonyParticipant).values({
    id: `${ceremonyCode}-${participant}`,
    ceremonyCode: ceremonyCode,
    participant: participant,
    joinedAt: Number(event.block.timestamp),
    blockNumber: event.block.number,
    transactionHash: event.transaction.hash,
  });

  // Atualizar estatísticas de participantes
  const stats = await context.db.find(ceremonyStats, { id: "global" });
  if (stats) {
    await context.db.update(ceremonyStats, { id: "global" }).set({
      totalParticipants: stats.totalParticipants + 1n,
      lastUpdated: Number(event.block.timestamp),
    });
  }
});

// Evento: EntryApproved
ponder.on("CeremonyFacet:EntryApproved", async ({ event, context }) => {
  const ceremonyCode = event.args.ceremonyCode;
  const participant = event.args.participant;
  
  console.log(`Entry approved for ${participant} in ceremony ${ceremonyCode}`);
});

// Evento: CeremonyConcluded
ponder.on("CeremonyFacet:CeremonyConcluded", async ({ event, context }) => {
  const ceremonyCode = event.args.ceremonyCode;
  
  console.log(`Processing CeremonyConcluded: ${ceremonyCode}`);
  
  // Atualizar status da cerimônia
  await context.db.update(ceremony, { id: ceremonyCode }).set({
    status: "concluded",
    concludedAt: Number(event.block.timestamp),
  });
});