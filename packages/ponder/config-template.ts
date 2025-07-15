import { createConfig } from "ponder";
import { http } from "viem";

export default createConfig({
  database: {
    kind: "sqlite",
    directory: "./.ponder/sqlite",
  },
  networks: {
    localhost: {
      chainId: 31337,
      transport: http("http://127.0.0.1:8545"),
    },
  },
  contracts: {
    CeremonyFacet: {
      network: "localhost",
      abi: [
        {
                "type": "event",
                "name": "CeremonyStarted",
                "inputs": [
                        {
                                "name": "ceremonyCode",
                                "type": "string",
                                "indexed": false
                        },
                        {
                                "name": "sprintNumber",
                                "type": "uint256",
                                "indexed": false
                        },
                        {
                                "name": "startTime",
                                "type": "uint256",
                                "indexed": false
                        },
                        {
                                "name": "scrumMaster",
                                "type": "address",
                                "indexed": true
                        }
                ]
        },
        {
                "type": "event",
                "name": "CeremonyEntryRequested",
                "inputs": [
                        {
                                "name": "ceremonyCode",
                                "type": "string",
                                "indexed": false
                        },
                        {
                                "name": "participant",
                                "type": "address",
                                "indexed": true
                        }
                ]
        },
        {
                "type": "event",
                "name": "EntryApproved",
                "inputs": [
                        {
                                "name": "ceremonyCode",
                                "type": "string",
                                "indexed": false
                        },
                        {
                                "name": "participant",
                                "type": "address",
                                "indexed": true
                        }
                ]
        },
        {
                "type": "event",
                "name": "CeremonyConcluded",
                "inputs": [
                        {
                                "name": "ceremonyCode",
                                "type": "string",
                                "indexed": false
                        },
                        {
                                "name": "endTime",
                                "type": "uint256",
                                "indexed": false
                        },
                        {
                                "name": "sprintNumber",
                                "type": "uint256",
                                "indexed": false
                        }
                ]
        }
],
      address: "0x4e85dc48a70da1298489d5b6fc2492767d98f384",
      startBlock: 4,
    },
    VotingFacet: {
      network: "localhost",
      abi: [
        {
                "type": "event",
                "name": "FunctionalityVoteOpened",
                "inputs": [
                        {
                                "name": "ceremonyCode",
                                "type": "string",
                                "indexed": false
                        },
                        {
                                "name": "functionalityCode",
                                "type": "string",
                                "indexed": false
                        },
                        {
                                "name": "sessionIndex",
                                "type": "uint256",
                                "indexed": false
                        }
                ]
        },
        {
                "type": "event",
                "name": "FunctionalityVoteCommitted",
                "inputs": [
                        {
                                "name": "ceremonyCode",
                                "type": "string",
                                "indexed": false
                        },
                        {
                                "name": "sessionIndex",
                                "type": "uint256",
                                "indexed": false
                        },
                        {
                                "name": "participant",
                                "type": "address",
                                "indexed": true
                        }
                ]
        },
        {
                "type": "event",
                "name": "FunctionalityVoteRevealed",
                "inputs": [
                        {
                                "name": "ceremonyCode",
                                "type": "string",
                                "indexed": false
                        },
                        {
                                "name": "sessionIndex",
                                "type": "uint256",
                                "indexed": false
                        },
                        {
                                "name": "participant",
                                "type": "address",
                                "indexed": true
                        },
                        {
                                "name": "voteValue",
                                "type": "uint256",
                                "indexed": false
                        }
                ]
        },
        {
                "type": "event",
                "name": "FunctionalityVoteClosed",
                "inputs": [
                        {
                                "name": "ceremonyCode",
                                "type": "string",
                                "indexed": false
                        },
                        {
                                "name": "sessionIndex",
                                "type": "uint256",
                                "indexed": false
                        },
                        {
                                "name": "closer",
                                "type": "address",
                                "indexed": true
                        }
                ]
        },
        {
                "type": "event",
                "name": "FunctionalityVoteCast",
                "inputs": [
                        {
                                "name": "ceremonyCode",
                                "type": "string",
                                "indexed": false
                        },
                        {
                                "name": "sessionIndex",
                                "type": "uint256",
                                "indexed": false
                        },
                        {
                                "name": "participant",
                                "type": "address",
                                "indexed": true
                        },
                        {
                                "name": "voteValue",
                                "type": "uint256",
                                "indexed": false
                        }
                ]
        },
        {
                "type": "event",
                "name": "BadgeBatchProcessed",
                "inputs": [
                        {
                                "name": "ceremonyCode",
                                "type": "string",
                                "indexed": false
                        },
                        {
                                "name": "sessionIndex",
                                "type": "uint256",
                                "indexed": false
                        },
                        {
                                "name": "batchSize",
                                "type": "uint256",
                                "indexed": false
                        }
                ]
        },
        {
                "type": "event",
                "name": "NFTBadgeUpdated",
                "inputs": [
                        {
                                "name": "participant",
                                "type": "address",
                                "indexed": true
                        },
                        {
                                "name": "tokenId",
                                "type": "uint256",
                                "indexed": false
                        }
                ]
        }
],
      address: "0x4d8e02bbfcf205828a8352af4376b165e123d7b0",
      startBlock: 4,
    },
    AdminFacet: {
      network: "localhost",
      abi: [
        {
                "type": "event",
                "name": "ExchangeRateUpdated",
                "inputs": [
                        {
                                "name": "newRate",
                                "type": "uint256",
                                "indexed": false
                        },
                        {
                                "name": "timestamp",
                                "type": "uint256",
                                "indexed": false
                        }
                ]
        }
],
      address: "0xf1078fd568ad76e49e6f88d1ff485402a086976b",
      startBlock: 4,
    },
    NFTFacet: {
      network: "localhost",
      abi: [
        {
                "type": "event",
                "name": "NFTPurchased",
                "inputs": [
                        {
                                "name": "buyer",
                                "type": "address",
                                "indexed": true
                        },
                        {
                                "name": "tokenId",
                                "type": "uint256",
                                "indexed": false
                        },
                        {
                                "name": "amountPaid",
                                "type": "uint256",
                                "indexed": false
                        }
                ]
        },
        {
                "type": "event",
                "name": "NFTRefunded",
                "inputs": [
                        {
                                "name": "buyer",
                                "type": "address",
                                "indexed": true
                        },
                        {
                                "name": "tokenId",
                                "type": "uint256",
                                "indexed": false
                        },
                        {
                                "name": "amountRefunded",
                                "type": "uint256",
                                "indexed": false
                        }
                ]
        }
],
      address: "0xe8f76a822b57b973c7a89006092364fff8f69040",
      startBlock: 4,
    },
  },
});