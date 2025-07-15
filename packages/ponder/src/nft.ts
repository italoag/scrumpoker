import { ponder } from "ponder:registry";
import { 
  badgeProcessing,
  nftBadgeUpdate,
  nftPurchase 
} from "ponder:schema";

// Evento: BadgeBatchProcessed
ponder.on("VotingFacet:BadgeBatchProcessed", async ({ event, context }) => {
  const ceremonyCode = event.args.ceremonyCode;
  const sessionIndex = event.args.sessionIndex;
  const batchSize = event.args.batchSize;
  
  // Registrar processamento de badges
  await context.db.insert(badgeProcessing).values({
    id: `${ceremonyCode}-${sessionIndex}-${event.block.timestamp}`,
    ceremonyCode: ceremonyCode,
    startIndex: Number(sessionIndex),
    endIndex: Number(sessionIndex) + Number(batchSize),
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

// Evento: NFTPurchased
ponder.on("NFTFacet:NFTPurchased", async ({ event, context }) => {
  const buyer = event.args.buyer;
  const tokenId = event.args.tokenId;
  const amountPaid = event.args.amountPaid;
  
  // Registrar compra de NFT
  await context.db.insert(nftPurchase).values({
    id: `${buyer}-${tokenId}`,
    buyer: buyer,
    tokenId: tokenId,
    amountPaid: amountPaid,
    purchasedAt: Number(event.block.timestamp),
    blockNumber: event.block.number,
    transactionHash: event.transaction.hash,
  });
});