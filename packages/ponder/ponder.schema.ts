import { onchainTable } from "ponder";

// Cerimônias do ScrumPoker
export const ceremony = onchainTable("ceremony", (t) => ({
  id: t.text().primaryKey(), // ceremonyCode
  creator: t.hex().notNull(),
  title: t.text().notNull(),
  description: t.text(),
  status: t.text().notNull(), // "created", "started", "concluded"
  createdAt: t.integer().notNull(),
  startedAt: t.integer(),
  concludedAt: t.integer(),
  blockNumber: t.bigint().notNull(),
  transactionHash: t.hex().notNull(),
}));

// Participantes das cerimônias
export const ceremonyParticipant = onchainTable("ceremony_participant", (t) => ({
  id: t.text().primaryKey(), // ceremonyCode + participant address
  ceremonyCode: t.text().notNull(),
  participant: t.hex().notNull(),
  joinedAt: t.integer().notNull(),
  blockNumber: t.bigint().notNull(),
  transactionHash: t.hex().notNull(),
}));

// Votações de funcionalidades
export const functionalityVote = onchainTable("functionality_vote", (t) => ({
  id: t.text().primaryKey(), // ceremonyCode + sessionIndex + participant
  ceremonyCode: t.text().notNull(),
  sessionIndex: t.bigint().notNull(),
  participant: t.hex().notNull(),
  voteValue: t.bigint(),
  isCommitted: t.boolean().notNull().default(false),
  isRevealed: t.boolean().notNull().default(false),
  committedAt: t.integer(),
  revealedAt: t.integer(),
  blockNumber: t.bigint().notNull(),
  transactionHash: t.hex().notNull(),
}));

// Sessões de votação de funcionalidades
export const functionalitySession = onchainTable("functionality_session", (t) => ({
  id: t.text().primaryKey(), // ceremonyCode + sessionIndex
  ceremonyCode: t.text().notNull(),
  sessionIndex: t.bigint().notNull(),
  functionalityCode: t.text().notNull(),
  status: t.text().notNull(), // "opened", "closed"
  openedAt: t.integer().notNull(),
  closedAt: t.integer(),
  closedBy: t.hex(),
  blockNumber: t.bigint().notNull(),
  transactionHash: t.hex().notNull(),
}));

// NFT Badges processados
export const badgeProcessing = onchainTable("badge_processing", (t) => ({
  id: t.text().primaryKey(), // ceremonyCode + startIndex + endIndex
  ceremonyCode: t.text().notNull(),
  startIndex: t.bigint().notNull(),
  endIndex: t.bigint().notNull(),
  processedAt: t.integer().notNull(),
  blockNumber: t.bigint().notNull(),
  transactionHash: t.hex().notNull(),
}));

// NFT Badge updates
export const nftBadgeUpdate = onchainTable("nft_badge_update", (t) => ({
  id: t.text().primaryKey(), // participant + timestamp
  participant: t.hex().notNull(),
  tokenId: t.bigint().notNull(),
  updatedAt: t.integer().notNull(),
  blockNumber: t.bigint().notNull(),
  transactionHash: t.hex().notNull(),
}));

// Compras de NFTs
export const nftPurchase = onchainTable("nft_purchase", (t) => ({
  id: t.text().primaryKey(), // buyer + tokenId
  buyer: t.hex().notNull(),
  tokenId: t.bigint().notNull(),
  amountPaid: t.bigint().notNull(),
  purchasedAt: t.integer().notNull(),
  blockNumber: t.bigint().notNull(),
  transactionHash: t.hex().notNull(),
}));

// Estatísticas gerais
export const ceremonyStats = onchainTable("ceremony_stats", (t) => ({
  id: t.text().primaryKey(),
  totalCeremonies: t.bigint().notNull().default(0n),
  totalParticipants: t.bigint().notNull().default(0n),
  totalVotes: t.bigint().notNull().default(0n),
  lastUpdated: t.integer().notNull(),
}));

// Solicitações de aprovação de cerimônias
export const ceremonyApprovalRequest = onchainTable("ceremony_approval_request", (t) => ({
  id: t.text().primaryKey(), // ceremonyCode + participant
  ceremonyCode: t.text().notNull(),
  participant: t.hex().notNull(),
  status: t.text().notNull().default("pending"), // "pending", "approved", "rejected"
  requestedAt: t.integer().notNull(),
  processedAt: t.integer(),
  processedBy: t.hex(),
  blockNumber: t.bigint().notNull(),
  transactionHash: t.hex().notNull(),
}));