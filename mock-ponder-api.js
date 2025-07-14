const express = require('express');
const cors = require('cors');
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Mock data baseado nos dados que sabemos que existem
const mockData = {
  ceremonys: {
    items: [
      {
        id: "CEREMONY0",
        creator: "0x1234567890123456789012345678901234567890",
        title: "Sprint Planning Ceremony",
        description: "Planning ceremony for sprint 1",
        status: "CONCLUDED",
        createdAt: "1700000000",
        startedAt: "1700001000",
        concludedAt: "1700002000",
        blockNumber: "15",
        transactionHash: "0xabcdef1234567890"
      },
      {
        id: "CEREMONY1",
        creator: "0x2345678901234567890123456789012345678901",
        title: "Daily Standup",
        description: "Daily standup meeting",
        status: "ACTIVE",
        createdAt: "1700010000",
        startedAt: "1700011000",
        concludedAt: null,
        blockNumber: "20",
        transactionHash: "0xabcdef1234567891"
      },
      {
        id: "CEREMONY2",
        creator: "0x3456789012345678901234567890123456789012",
        title: "Sprint Review",
        description: "Review of completed sprint",
        status: "PENDING",
        createdAt: "1700020000",
        startedAt: null,
        concludedAt: null,
        blockNumber: "25",
        transactionHash: "0xabcdef1234567892"
      },
      {
        id: "CEREMONY3",
        creator: "0x4567890123456789012345678901234567890123",
        title: "Retrospective",
        description: "Sprint retrospective meeting",
        status: "CONCLUDED",
        createdAt: "1700030000",
        startedAt: "1700031000",
        concludedAt: "1700032000",
        blockNumber: "30",
        transactionHash: "0xabcdef1234567893"
      },
      {
        id: "CEREMONY4",
        creator: "0x5678901234567890123456789012345678901234",
        title: "Backlog Refinement",
        description: "Refining product backlog",
        status: "ACTIVE",
        createdAt: "1700040000",
        startedAt: "1700041000",
        concludedAt: null,
        blockNumber: "35",
        transactionHash: "0xabcdef1234567894"
      }
    ]
  },
  ceremonyParticipants: {
    items: [
      {
        id: "PARTICIPANT_1",
        ceremonyCode: "CEREMONY0",
        participant: "0x1111111111111111111111111111111111111111",
        joinedAt: "1700001100",
        blockNumber: "16",
        transactionHash: "0xparticipant001"
      },
      {
        id: "PARTICIPANT_2",
        ceremonyCode: "CEREMONY1",
        participant: "0x2222222222222222222222222222222222222222",
        joinedAt: "1700011100",
        blockNumber: "21",
        transactionHash: "0xparticipant002"
      }
    ]
  },
  functionalitySessions: {
    items: [
      {
        id: "SESSION_1",
        ceremonyCode: "CEREMONY0",
        sessionIndex: "1",
        functionalityCode: "USER_STORY_1",
        status: "CLOSED",
        openedAt: "1700001200",
        closedAt: "1700001800",
        closedBy: "0x1234567890123456789012345678901234567890",
        blockNumber: "17",
        transactionHash: "0xsession001"
      }
    ]
  },
  functionalityVotes: {
    items: [
      {
        id: "VOTE_1",
        ceremonyCode: "CEREMONY0",
        sessionIndex: "1",
        participant: "0x1111111111111111111111111111111111111111",
        voteValue: "5",
        isCommitted: true,
        isRevealed: true,
        committedAt: "1700001300",
        revealedAt: "1700001400",
        blockNumber: "18",
        transactionHash: "0xvote001"
      }
    ]
  },
  ceremonyStatss: {
    items: [
      {
        id: "STATS_1",
        totalCeremonies: "5",
        totalParticipants: "10",
        totalVotes: "25",
        lastUpdated: "1700050000"
      }
    ]
  }
};

// GraphQL endpoint
app.post('/', (req, res) => {
  console.log('Received GraphQL query:', req.body.query);
  
  // Simple query parsing - in real implementation, you'd use a proper GraphQL parser
  if (req.body.query) {
    res.json({ data: mockData });
  } else {
    res.status(400).json({ error: 'No query provided' });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Mock Ponder API is running' });
});

const PORT = 42069;
app.listen(PORT, () => {
  console.log(`🚀 Mock Ponder API running on http://localhost:${PORT}`);
  console.log(`📊 Serving mock ceremony data`);
});