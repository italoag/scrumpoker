import { createConfig } from "ponder";
import { http } from "viem";

export default createConfig({
  networks: {
    localhost: {
      chainId: 1337,
      transport: http("http://127.0.0.1:8545"),
    },
  },
  contracts: {
    CeremonyFacet: {
      network: "localhost",
      abi: [
        {
          type: "event",
          name: "CeremonyConcluded",
          inputs: [
            {
              name: "ceremonyCode",
              type: "string",
              indexed: false,
              internalType: "string",
            },
            {
              name: "endTime",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
            {
              name: "sprintNumber",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "CeremonyEntryRequested",
          inputs: [
            {
              name: "ceremonyCode",
              type: "string",
              indexed: false,
              internalType: "string",
            },
            {
              name: "participant",
              type: "address",
              indexed: true,
              internalType: "address",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "CeremonyStarted",
          inputs: [
            {
              name: "ceremonyCode",
              type: "string",
              indexed: false,
              internalType: "string",
            },
            {
              name: "sprintNumber",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
            {
              name: "startTime",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
            {
              name: "scrumMaster",
              type: "address",
              indexed: true,
              internalType: "address",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "EntryApproved",
          inputs: [
            {
              name: "ceremonyCode",
              type: "string",
              indexed: false,
              internalType: "string",
            },
            {
              name: "participant",
              type: "address",
              indexed: true,
              internalType: "address",
            },
          ],
          anonymous: false,
        }
      ],
      address: "0xdeb366053b16457d1fe2a6b8559ff713c1bbeb69",
      startBlock: 0,
    },
    VotingFacet: {
      network: "localhost",
      abi: [
        {
          type: "event",
          name: "FunctionalityVoteCast",
          inputs: [
            {
              name: "ceremonyCode",
              type: "string",
              indexed: false,
              internalType: "string",
            },
            {
              name: "sessionIndex",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
            {
              name: "participant",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "voteValue",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "FunctionalityVoteClosed",
          inputs: [
            {
              name: "ceremonyCode",
              type: "string",
              indexed: false,
              internalType: "string",
            },
            {
              name: "sessionIndex",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
            {
              name: "closer",
              type: "address",
              indexed: true,
              internalType: "address",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "FunctionalityVoteCommitted",
          inputs: [
            {
              name: "ceremonyCode",
              type: "string",
              indexed: false,
              internalType: "string",
            },
            {
              name: "sessionIndex",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
            {
              name: "participant",
              type: "address",
              indexed: true,
              internalType: "address",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "FunctionalityVoteOpened",
          inputs: [
            {
              name: "ceremonyCode",
              type: "string",
              indexed: false,
              internalType: "string",
            },
            {
              name: "functionalityCode",
              type: "string",
              indexed: false,
              internalType: "string",
            },
            {
              name: "sessionIndex",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "FunctionalityVoteRevealed",
          inputs: [
            {
              name: "ceremonyCode",
              type: "string",
              indexed: false,
              internalType: "string",
            },
            {
              name: "sessionIndex",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
            {
              name: "participant",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "voteValue",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "BadgeBatchProcessed",
          inputs: [
            {
              name: "ceremonyCode",
              type: "string",
              indexed: false,
              internalType: "string",
            },
            {
              name: "startIndex",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
            {
              name: "endIndex",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "NFTBadgeUpdated",
          inputs: [
            {
              name: "participant",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "tokenId",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        }
      ],
      address: "0x960acb1bb927842ee6718ff8d3550cce942228c2",
      startBlock: 0,
    },
  },
});