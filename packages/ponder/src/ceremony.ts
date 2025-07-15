import { ponder } from "ponder:registry";
import { 
  ceremony, 
  ceremonyParticipant, 
  ceremonyStats,
  ceremonyApprovalRequest
} from "ponder:schema";

// Evento: CeremonyStarted - Criação real de cerimônia
ponder.on("CeremonyFacet:CeremonyStarted", async ({ event, context }) => {
  try {
    const ceremonyCode = event.args.ceremonyCode;
    const scrumMaster = event.args.scrumMaster;
    const sprintNumber = event.args.sprintNumber;
    const startTime = event.args.startTime;
    
    console.log(`Processing CeremonyStarted: ${ceremonyCode}`, {
      scrumMaster,
      sprintNumber: sprintNumber.toString(),
      startTime: startTime.toString(),
      blockNumber: event.block.number.toString(),
      timestamp: event.block.timestamp.toString()
    });
  
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
  } catch (error) {
    console.error(`Error processing CeremonyStarted for ${event.args.ceremonyCode}:`, error);
    throw error; // Re-throw para que o Ponder saiba que houve erro
  }
});

// Evento: CeremonyEntryRequested - Gerenciamento de participantes
ponder.on("CeremonyFacet:CeremonyEntryRequested", async ({ event, context }) => {
  try {
    const ceremonyCode = event.args.ceremonyCode;
    const participant = event.args.participant;
    
    console.log(`Processing CeremonyEntryRequested: ${participant} for ${ceremonyCode}`);
  
  // Criar solicitação de aprovação
  await context.db.insert(ceremonyApprovalRequest).values({
    id: `${ceremonyCode}-${participant}`,
    ceremonyCode: ceremonyCode,
    participant: participant,
    status: "pending",
    requestedAt: Number(event.block.timestamp),
    blockNumber: event.block.number,
    transactionHash: event.transaction.hash,
  });

  console.log(`Created approval request for ${participant} in ceremony ${ceremonyCode}`);
  } catch (error) {
    console.error(`Error processing CeremonyEntryRequested:`, error);
    throw error;
  }
});

// Evento: EntryApproved
ponder.on("CeremonyFacet:EntryApproved", async ({ event, context }) => {
  try {
    const ceremonyCode = event.args.ceremonyCode;
    const participant = event.args.participant;
    
    console.log(`Entry approved for ${participant} in ceremony ${ceremonyCode}`);
    
    // Atualizar solicitação de aprovação
    await context.db.update(ceremonyApprovalRequest, { 
      id: `${ceremonyCode}-${participant}` 
    }).set({
      status: "approved",
      processedAt: Number(event.block.timestamp),
      processedBy: event.transaction.from, // Quem aprovou
    });

    // Adicionar como participante efetivo
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

    console.log(`Approved and added ${participant} to ceremony ${ceremonyCode}`);
  } catch (error) {
    console.error(`Error processing EntryApproved:`, error);
    throw error;
  }
});

// Evento: CeremonyConcluded
ponder.on("CeremonyFacet:CeremonyConcluded", async ({ event, context }) => {
  try {
    const ceremonyCode = event.args.ceremonyCode;
    
    console.log(`Processing CeremonyConcluded: ${ceremonyCode}`);
    
    // Atualizar status da cerimônia
    await context.db.update(ceremony, { id: ceremonyCode }).set({
      status: "concluded",
      concludedAt: Number(event.block.timestamp),
    });
  } catch (error) {
    console.error(`Error processing CeremonyConcluded:`, error);
    throw error;
  }
});