import { ponder } from "ponder:registry";
import { 
  badgeProcessing,
  nftBadgeUpdate 
} from "ponder:schema";

// Evento: BadgeBatchProcessed
ponder.on("VotingFacet:BadgeBatchProcessed", async ({ event, context }) => {
  const ceremonyCode = event.args.ceremonyCode;
  const startIndex = event.args.startIndex;
  const endIndex = event.args.endIndex;
  
  // Registrar processamento de badges
  await context.db.insert(badgeProcessing).values({
    id: `${ceremonyCode}-${startIndex}-${endIndex}`,
    ceremonyCode: ceremonyCode,
    startIndex: startIndex,
    endIndex: endIndex,
    processedAt: Number(event.block.timestamp),
    blockNumber: event.block.number,
    transactionHash: event.transaction.hash,
  });
});

// Evento: NFTBadgeUpdated
ponder.on("VotingFacet:NFTBadgeUpdated", async ({ event, context }) => {
  const participant = event.args.participant;
  const tokenId = event.args.tokenId;
  
  // Registrar atualização de NFT badge
  await context.db.insert(nftBadgeUpdate).values({
    id: `${participant}-${event.block.timestamp}`,
    participant: participant,
    tokenId: tokenId,
    updatedAt: Number(event.block.timestamp),
    blockNumber: event.block.number,
    transactionHash: event.transaction.hash,
  });
});