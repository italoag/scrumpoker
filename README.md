# 🏗 Scrum Poker

<h4 align="center">
  <a href="#overview">Overview</a> |
  <a href="#key-features">Key Features</a> |
  <a href="#technical-architecture">Architecture</a> |
  <a href="#getting-started">Getting Started</a>
</h4>

🧪 A decentralized application built on Ethereum that revolutionizes the way development teams conduct sprint planning sessions. This Web3 application implements the popular Scrum Poker (or Planning Poker) estimation technique on the blockchain, providing transparency, immutability, and incentivization for accurate estimations.

⚙️ Built using NextJS, RainbowKit, Foundry, Wagmi, Viem, and Typescript with Diamond Protocol (EIP-2535) smart contracts.

- ✅ **Decentralized Ceremonies**: Create and manage sprint planning sessions on-chain with unique access codes
- 🪝 **NFT-Based Badge System**: Earn NFT badges based on estimation accuracy and participation
- 🧱 **Role-Based Access Control**: Dedicated roles for Scrum Masters, Product Owners, and Developers
- 🔥 **Feature Voting**: Vote on user stories and functionality with immutable results
- 🔐 **Tokenized Incentives**: Economic incentives for active and accurate participation
- 🤖 **Modular Smart Contract Architecture**: Leverages the Diamond Protocol for upgradability and modularity

## Overview

Scrum Poker is a decentralized application that brings the popular Scrum Poker planning technique to the blockchain. It enables development teams to conduct transparent, immutable sprint planning sessions with incentives for accurate estimations.

## Key Features

- **Decentralized Planning Sessions**: Conduct sprint planning on-chain
- **NFT Badges for Participation**: Earn rewards based on estimation accuracy
- **Blockchain Transparency**: All votes and outcomes are stored on-chain
- **Role-Based Governance**: Special roles for Scrum Masters and team members

## Technical Architecture

### Smart Contract Implementation

The Scrum Poker is implemented using the Diamond Protocol (EIP-2535) with the Solarity 3.1 library, making the contract modular, upgradeable, and efficient.

#### Core Contracts

- **ScrumPokerDiamond**: Main contract implementing the Diamond pattern
- **ScrumPokerStorage**: Shared storage for all facets
- **DiamondInit**: Initialization contract for setting up all facets

#### Specialized Facets

The system is divided into specialized facets:

1. **AdminFacet**: Manages administrative settings and access control
2. **NFTFacet**: Implements NFT badge functionality
3. **CeremonyFacet**: Handles ceremonies (sprints) and participant management
4. **VotingFacet**: Manages various voting processes

## Requirements

Before you begin, you need to install the following tools:

- [Node (>= v18.18)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

## Getting Started

To get started with Scrum Poker, follow these steps:

1. Install dependencies:

```bash
cd scrumpoker
yarn install
```

2. Run a local network in the first terminal:

```bash
yarn chain
```

This command starts a local Ethereum network using Foundry for testing and development.

3. Deploy the Scrum Poker contracts:

```bash
yarn deploy
```

This deploys the Diamond Protocol contracts that make up the Scrum Poker dApp.

4. Start your NextJS app:

```bash
yarn start
```

Visit your app on: `http://localhost:3000`. You can interact with the Scrum Poker dApp to create ceremonies, join planning sessions, vote on user stories, and earn NFT badges.

### Development

- Run smart contract tests with `yarn foundry:test`
- Edit smart contracts in `packages/foundry/contracts` - key files include the Diamond facets
- Edit the frontend at `packages/nextjs/app/`
- Modify deployment scripts in `packages/foundry/script`

## Using the Scrum Poker dApp

The Scrum Poker dApp provides multiple functionalities for different user roles:

### For Administrators

```javascript
// Update exchange rate
adminFacet.updateExchangeRate(newRate);

// Pause/unpause the contract
adminFacet.pause();
adminFacet.unpause();

// Grant roles to users
adminFacet.grantRole(SCRUM_MASTER_ROLE, address);
```

### For NFT Badge Management

```javascript
// Purchase NFT badges
nftFacet.purchaseNFT({ value: exchangeRate }, "Developer Badge", "ipfs://badge-uri");

// View badge data
const badgeData = await nftFacet.getBadgeData(tokenId);
```

### For Ceremonies (Sprints)

```javascript
// Start a new ceremony (sprint)
const code = await ceremonyFacet.startCeremony(sprintNumber);

// Request to join a ceremony
await ceremonyFacet.requestCeremonyEntry(code);

// Approve participant entry (Scrum Master only)
await ceremonyFacet.approveEntry(code, participantAddress);

// Conclude a ceremony
await ceremonyFacet.concludeCeremony(code);
```

### For Voting

```javascript
// Vote in a ceremony
await votingFacet.vote(code, voteValue);

// Open voting for a specific functionality
await votingFacet.openFunctionalityVote(code, functionalityCode);

// Vote on functionality
await votingFacet.voteFunctionality(code, sessionIndex, voteValue);

// Update badges with voting results
await votingFacet.updateBadges(code);
```

## Event Indexing with Ponder

The Scrum Poker dApp uses Ponder for event indexing to track important events like ceremony creation, voting results, and badge awards.

### Setup

Ponder configuration is in `packages/ponder/ponder.config.ts`, automatically using deployed contracts from the blockchain network configured in `packages/nextjs/scaffold.config.ts`.

### Schema

The Scrum Poker schema in `packages/ponder/ponder.schema.ts` models entities like:
- Ceremonies
- Participants
- Votes
- NFT Badges
- Rewards

### Development Server

Start the Ponder server to index events and provide the GraphQL API:

```bash
yarn ponder:dev
```

Access the GraphQL interface at http://localhost:42069

### Querying Data

In your frontend, you can query ceremony and voting data using React Query:

```typescript
// Example query for a ceremony's voting results
const { data: ceremonyResults } = useQuery({
  queryKey: ["ceremonyResults", ceremonyCode],
  queryFn: async () => {
    const response = await fetch(
      `${process.env.NEXT_PUBLIC_PONDER_URL}/graphql`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          query: `
            query GetCeremonyResults($code: String!) {
              ceremony(code: $code) {
                code
                sprintNumber
                votes {
                  voter
                  value
                  timestamp
                }
                concluded
              }
            }
          `,
          variables: { code: ceremonyCode }
        })
      }
    );
    const json = await response.json();
    return json.data.ceremony;
  }
});
```

## Security Features

The Scrum Poker implements multiple security measures at the smart contract level:

- **Reentrancy Protection**: Guards against reentrancy attacks in all fund-related functions
- **Withdrawal Pattern**: Secure fund transfers using the withdrawal pattern
- **Role-Based Access Control**: Granular permissions for different user types
- **Emergency Pause**: Ability to pause contract operations in case of emergencies
- **State Verification**: Thorough validation checks for all operations

## Contract Upgradeability

One of the key advantages of using the Diamond Protocol (EIP-2535) is the ability to upgrade contracts without losing state:

1. Deploy new facet implementations
2. Update the Diamond contract to point to the new facets
3. Remove or replace obsolete facets

This can be done using the `diamondCut` method of the Diamond contract.

## Contributing

We welcome contributions to improve the Scrum Poker dApp! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Acknowledgments

- Built with [Scaffold-ETH 2](https://github.com/scaffold-eth/scaffold-eth-2)
- Diamond Protocol implementation based on [EIP-2535](https://eips.ethereum.org/EIPS/eip-2535)
- [Solarity](https://github.com/solarity) for Diamond Protocol helpers

## Documentation

Visit our [docs](https://docs.scaffoldeth.io) to learn how to start building with Scaffold-ETH 2.

To know more about its features, check out our [website](https://scaffoldeth.io).

## Contributing

We welcome contributions to Scrum Poker!

Please see [CONTRIBUTING.MD](https://github.com/italoag/scrumpoker/blob/main/CONTRIBUTING.md) for more information and guidelines for contributing to Scrum Poker.