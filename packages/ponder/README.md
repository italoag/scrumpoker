# Ponder Indexing Service - ScrumPoker DApp

## Overview
This Ponder service indexes events from the ScrumPoker Diamond pattern contracts deployed on the local blockchain. It provides a GraphQL API for querying ceremony data, votes, and NFT badge information.

## Configuration

### Contracts Indexed
- **CeremonyFacet** (`0xdeb366053b16457d1fe2a6b8559ff713c1bbeb69`)
  - CeremonyEntryRequested
  - CeremonyStarted
  - CeremonyConcluded
  - EntryApproved

- **VotingFacet** (`0x960acb1bb927842ee6718ff8d3550cce942228c2`)
  - FunctionalityVoteOpened
  - FunctionalityVoteCommitted
  - FunctionalityVoteRevealed
  - FunctionalityVoteCast
  - FunctionalityVoteClosed
  - BadgeBatchProcessed
  - NFTBadgeUpdated

### Database Schema

#### Tables
1. **ceremony** - Main ceremony information
2. **ceremony_participant** - Participants in each ceremony
3. **functionality_vote** - Individual votes on functionalities
4. **functionality_session** - Voting sessions for functionalities
5. **badge_processing** - NFT badge batch processing events
6. **nft_badge_update** - Individual NFT badge updates
7. **ceremony_stats** - Global statistics

## Usage

### Development
```bash
npm run dev
```

### Code Generation
```bash
npm run codegen
```

### GraphQL Server
The GraphQL server will be available at `http://localhost:42069` when running in development mode.

### Example Queries

#### Get all ceremonies
```graphql
query {
  ceremonies {
    id
    creator
    title
    status
    createdAt
    participantCount
  }
}
```

#### Get votes for a ceremony
```graphql
query {
  functionalityVotes(where: { ceremonyCode: "CEREMONY_CODE" }) {
    participant
    voteValue
    isRevealed
    revealedAt
  }
}
```

## Files Structure

- `ponder.config.ts` - Main configuration with contract addresses and ABIs
- `ponder.schema.ts` - Database schema definitions
- `src/ceremony.ts` - Indexers for ceremony-related events
- `src/voting.ts` - Indexers for voting-related events
- `src/nft.ts` - Indexers for NFT badge events

## Notes

- The configuration uses manually defined ABIs to avoid dependency issues
- Contract addresses are hardcoded for the local development environment (chainId: 1337)
- The service automatically creates ceremonies when the first participant requests entry
- All timestamps are stored as Unix timestamps (seconds since epoch)