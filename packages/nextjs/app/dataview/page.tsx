"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { gql, request } from "graphql-request";
import type { NextPage } from "next";
import { Address } from "~~/components/scaffold-eth";

// Tipos para os dados do ScrumPoker
type Ceremony = {
  id: string;
  creator: `0x${string}`;
  title: string;
  description?: string;
  status: string;
  createdAt: number;
  startedAt?: number;
  concludedAt?: number;
  blockNumber: bigint;
  transactionHash: `0x${string}`;
};

type CeremonyParticipant = {
  id: string;
  ceremonyCode: string;
  participant: `0x${string}`;
  joinedAt: number;
  blockNumber: bigint;
  transactionHash: `0x${string}`;
};

type FunctionalitySession = {
  id: string;
  ceremonyCode: string;
  sessionIndex: bigint;
  functionalityCode: string;
  status: string;
  openedAt: number;
  closedAt?: number;
  closedBy?: `0x${string}`;
  blockNumber: bigint;
  transactionHash: `0x${string}`;
};

type FunctionalityVote = {
  id: string;
  ceremonyCode: string;
  sessionIndex: bigint;
  participant: `0x${string}`;
  voteValue?: bigint;
  isCommitted: boolean;
  isRevealed: boolean;
  committedAt?: number;
  revealedAt?: number;
  blockNumber: bigint;
  transactionHash: `0x${string}`;
};

type CeremonyStats = {
  id: string;
  totalCeremonies: bigint;
  totalParticipants: bigint;
  totalVotes: bigint;
  lastUpdated: number;
};

type ScrumPokerData = {
  ceremonys: { items: Ceremony[] };
  ceremonyParticipants: { items: CeremonyParticipant[] };
  functionalitySessions: { items: FunctionalitySession[] };
  functionalityVotes: { items: FunctionalityVote[] };
  ceremonyStatss: { items: CeremonyStats[] };
};

const fetchScrumPokerData = async () => {
  // Durante SSR, retornar dados vazios mas permitir que o cliente faça o fetch
  if (typeof window === "undefined") {
    return {
      ceremonys: { items: [] },
      ceremonyParticipants: { items: [] },
      functionalitySessions: { items: [] },
      functionalityVotes: { items: [] },
      ceremonyStatss: { items: [] },
    };
  }

  const ScrumPokerQuery = gql`
    query ScrumPokerData {
      ceremonys(orderBy: "createdAt", orderDirection: "desc") {
        items {
          id
          creator
          title
          description
          status
          createdAt
          startedAt
          concludedAt
          blockNumber
          transactionHash
        }
      }
      ceremonyParticipants(orderBy: "joinedAt", orderDirection: "desc") {
        items {
          id
          ceremonyCode
          participant
          joinedAt
          blockNumber
          transactionHash
        }
      }
      functionalitySessions(orderBy: "openedAt", orderDirection: "desc") {
        items {
          id
          ceremonyCode
          sessionIndex
          functionalityCode
          status
          openedAt
          closedAt
          closedBy
          blockNumber
          transactionHash
        }
      }
      functionalityVotes(orderBy: "committedAt", orderDirection: "desc") {
        items {
          id
          ceremonyCode
          sessionIndex
          participant
          voteValue
          isCommitted
          isRevealed
          committedAt
          revealedAt
          blockNumber
          transactionHash
        }
      }
      ceremonyStatss {
        items {
          id
          totalCeremonies
          totalParticipants
          totalVotes
          lastUpdated
        }
      }
    }
  `;

  try {
    console.log("Fetching from Ponder URL:", process.env.NEXT_PUBLIC_PONDER_URL || "http://localhost:42069");

    const data = await request<ScrumPokerData>(
      process.env.NEXT_PUBLIC_PONDER_URL || "http://localhost:42069",
      ScrumPokerQuery,
    );

    console.log("Successfully fetched data:", data);
    return data;
  } catch (error) {
    console.error("Failed to fetch ScrumPoker data from Ponder:", error);
    console.error("Error details:", {
      message: error instanceof Error ? error.message : "Unknown error",
      stack: error instanceof Error ? error.stack : undefined,
      url: process.env.NEXT_PUBLIC_PONDER_URL || "http://localhost:42069",
    });

    return {
      ceremonys: { items: [] },
      ceremonyParticipants: { items: [] },
      functionalitySessions: { items: [] },
      functionalityVotes: { items: [] },
      ceremonyStatss: { items: [] },
    };
  }
};

const ScrumPokerDashboard: NextPage = () => {
  const [activeTab, setActiveTab] = useState<"overview" | "ceremonies" | "sessions" | "votes" | "participants">(
    "overview",
  );

  // Debug: verificar se a variável de ambiente está sendo carregada
  useEffect(() => {
    console.log("Environment check:");
    console.log("NEXT_PUBLIC_PONDER_URL:", process.env.NEXT_PUBLIC_PONDER_URL);
    console.log("Window object exists:", typeof window !== "undefined");
  }, []);

  const {
    data: scrumPokerData,
    isLoading,
    error,
  } = useQuery({
    queryKey: ["scrumPokerData"],
    queryFn: fetchScrumPokerData,
    refetchInterval: 5000, // Atualizar a cada 5 segundos
  });

  const formatTimestamp = (timestamp: number) => {
    return new Date(timestamp * 1000).toLocaleString();
  };

  const getStatusBadge = (status: string) => {
    const statusColors = {
      created: "badge-info",
      started: "badge-success",
      concluded: "badge-neutral",
      opened: "badge-warning",
      closed: "badge-error",
    };
    return `badge ${statusColors[status as keyof typeof statusColors] || "badge-ghost"}`;
  };

  const stats = scrumPokerData?.ceremonyStatss?.items?.[0];

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5 text-center">
          <h1 className="text-4xl font-bold">ScrumPoker Dashboard</h1>
          <div>
            <p>Real-time monitoring of ScrumPoker ceremonies, voting sessions, and participant activities.</p>
            <p>
              Powered by{" "}
              <a target="_blank" href="https://ponder.sh/" className="underline font-bold text-nowrap">
                Ponder
              </a>{" "}
              blockchain indexing framework.
            </p>
          </div>

          {/* Estatísticas Gerais */}
          {stats && (
            <div className="stats shadow mt-6">
              <div className="stat">
                <div className="stat-title">Total Ceremonies</div>
                <div className="stat-value">{stats.totalCeremonies.toString()}</div>
              </div>
              <div className="stat">
                <div className="stat-title">Total Participants</div>
                <div className="stat-value">{stats.totalParticipants.toString()}</div>
              </div>
              <div className="stat">
                <div className="stat-title">Total Votes</div>
                <div className="stat-value">{stats.totalVotes.toString()}</div>
              </div>
            </div>
          )}

          {/* Navegação por Abas */}
          <div className="tabs tabs-boxed mt-6">
            <button
              className={`tab ${activeTab === "overview" ? "tab-active" : ""}`}
              onClick={() => setActiveTab("overview")}
            >
              Overview
            </button>
            <button
              className={`tab ${activeTab === "ceremonies" ? "tab-active" : ""}`}
              onClick={() => setActiveTab("ceremonies")}
            >
              Ceremonies
            </button>
            <button
              className={`tab ${activeTab === "sessions" ? "tab-active" : ""}`}
              onClick={() => setActiveTab("sessions")}
            >
              Sessions
            </button>
            <button
              className={`tab ${activeTab === "votes" ? "tab-active" : ""}`}
              onClick={() => setActiveTab("votes")}
            >
              Votes
            </button>
            <button
              className={`tab ${activeTab === "participants" ? "tab-active" : ""}`}
              onClick={() => setActiveTab("participants")}
            >
              Participants
            </button>
          </div>
        </div>

        <div className="flex-grow bg-base-300 w-full mt-8 px-8 py-12">
          {isLoading && (
            <div className="flex items-center flex-col flex-grow pt-12">
              <div className="loading loading-dots loading-md"></div>
              <p className="mt-4">Loading ScrumPoker data...</p>
            </div>
          )}

          {error && (
            <div className="alert alert-error">
              <span>Failed to load data. Make sure Ponder server is running on port 42069.</span>
            </div>
          )}

          {scrumPokerData && !isLoading && (
            <>
              {/* Overview Tab */}
              {activeTab === "overview" && (
                <div>
                  <h2 className="text-center text-3xl font-bold mb-6">System Overview</h2>

                  {/* Recent Activity */}
                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    {/* Recent Ceremonies */}
                    <div className="card bg-base-100 shadow-xl">
                      <div className="card-body">
                        <h3 className="card-title">Recent Ceremonies</h3>
                        {scrumPokerData.ceremonys.items.slice(0, 3).map(ceremony => (
                          <div key={ceremony.id} className="flex items-center justify-between border-b pb-2">
                            <div>
                              <p className="font-semibold">{ceremony.title}</p>
                              <p className="text-sm opacity-70">{ceremony.id}</p>
                            </div>
                            <div className="text-right">
                              <div className={getStatusBadge(ceremony.status)}>{ceremony.status}</div>
                              <p className="text-xs">{formatTimestamp(ceremony.createdAt)}</p>
                            </div>
                          </div>
                        ))}
                        {scrumPokerData.ceremonys.items.length === 0 && (
                          <p className="text-center opacity-70">No ceremonies found</p>
                        )}
                      </div>
                    </div>

                    {/* Recent Sessions */}
                    <div className="card bg-base-100 shadow-xl">
                      <div className="card-body">
                        <h3 className="card-title">Recent Voting Sessions</h3>
                        {scrumPokerData.functionalitySessions.items.slice(0, 3).map(session => (
                          <div key={session.id} className="flex items-center justify-between border-b pb-2">
                            <div>
                              <p className="font-semibold">{session.functionalityCode}</p>
                              <p className="text-sm opacity-70">Session #{session.sessionIndex.toString()}</p>
                            </div>
                            <div className="text-right">
                              <div className={getStatusBadge(session.status)}>{session.status}</div>
                              <p className="text-xs">{formatTimestamp(session.openedAt)}</p>
                            </div>
                          </div>
                        ))}
                        {scrumPokerData.functionalitySessions.items.length === 0 && (
                          <p className="text-center opacity-70">No sessions found</p>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Ceremonies Tab */}
              {activeTab === "ceremonies" && (
                <div>
                  <h2 className="text-center text-3xl font-bold mb-6">Ceremonies</h2>
                  {scrumPokerData.ceremonys.items.length === 0 ? (
                    <div className="text-center">
                      <p className="text-xl opacity-70">No ceremonies found</p>
                      <p className="mt-2">Create a ceremony from the main DApp to see it here.</p>
                    </div>
                  ) : (
                    <div className="grid gap-4">
                      {scrumPokerData.ceremonys.items.map(ceremony => (
                        <div key={ceremony.id} className="card bg-base-100 shadow-xl">
                          <div className="card-body">
                            <div className="flex justify-between items-start">
                              <div>
                                <h3 className="card-title">{ceremony.title}</h3>
                                <p className="text-sm opacity-70 mb-2">Code: {ceremony.id}</p>
                                {ceremony.description && <p>{ceremony.description}</p>}
                              </div>
                              <div className={getStatusBadge(ceremony.status)}>{ceremony.status}</div>
                            </div>
                            <div className="grid grid-cols-2 gap-4 mt-4">
                              <div>
                                <p className="text-sm font-semibold">Creator:</p>
                                <Address address={ceremony.creator} />
                              </div>
                              <div>
                                <p className="text-sm font-semibold">Created:</p>
                                <p className="text-sm">{formatTimestamp(ceremony.createdAt)}</p>
                              </div>
                              {ceremony.startedAt && (
                                <div>
                                  <p className="text-sm font-semibold">Started:</p>
                                  <p className="text-sm">{formatTimestamp(ceremony.startedAt)}</p>
                                </div>
                              )}
                              {ceremony.concludedAt && (
                                <div>
                                  <p className="text-sm font-semibold">Concluded:</p>
                                  <p className="text-sm">{formatTimestamp(ceremony.concludedAt)}</p>
                                </div>
                              )}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* Sessions Tab */}
              {activeTab === "sessions" && (
                <div>
                  <h2 className="text-center text-3xl font-bold mb-6">Voting Sessions</h2>
                  {scrumPokerData.functionalitySessions.items.length === 0 ? (
                    <div className="text-center">
                      <p className="text-xl opacity-70">No voting sessions found</p>
                    </div>
                  ) : (
                    <div className="grid gap-4">
                      {scrumPokerData.functionalitySessions.items.map(session => (
                        <div key={session.id} className="card bg-base-100 shadow-xl">
                          <div className="card-body">
                            <div className="flex justify-between items-start">
                              <div>
                                <h3 className="card-title">{session.functionalityCode}</h3>
                                <p className="text-sm opacity-70">Session #{session.sessionIndex.toString()}</p>
                                <p className="text-sm opacity-70">Ceremony: {session.ceremonyCode}</p>
                              </div>
                              <div className={getStatusBadge(session.status)}>{session.status}</div>
                            </div>
                            <div className="grid grid-cols-2 gap-4 mt-4">
                              <div>
                                <p className="text-sm font-semibold">Opened:</p>
                                <p className="text-sm">{formatTimestamp(session.openedAt)}</p>
                              </div>
                              {session.closedAt && (
                                <div>
                                  <p className="text-sm font-semibold">Closed:</p>
                                  <p className="text-sm">{formatTimestamp(session.closedAt)}</p>
                                </div>
                              )}
                              {session.closedBy && (
                                <div>
                                  <p className="text-sm font-semibold">Closed by:</p>
                                  <Address address={session.closedBy} />
                                </div>
                              )}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* Votes Tab */}
              {activeTab === "votes" && (
                <div>
                  <h2 className="text-center text-3xl font-bold mb-6">Functionality Votes</h2>
                  {scrumPokerData.functionalityVotes.items.length === 0 ? (
                    <div className="text-center">
                      <p className="text-xl opacity-70">No votes found</p>
                    </div>
                  ) : (
                    <div className="grid gap-4">
                      {scrumPokerData.functionalityVotes.items.map(vote => (
                        <div key={vote.id} className="card bg-base-100 shadow-xl">
                          <div className="card-body">
                            <div className="flex justify-between items-start">
                              <div>
                                <h3 className="card-title">Session #{vote.sessionIndex.toString()}</h3>
                                <p className="text-sm opacity-70">Ceremony: {vote.ceremonyCode}</p>
                              </div>
                              <div className="flex gap-2">
                                {vote.isCommitted && <div className="badge badge-info">Committed</div>}
                                {vote.isRevealed && <div className="badge badge-success">Revealed</div>}
                              </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4 mt-4">
                              <div>
                                <p className="text-sm font-semibold">Participant:</p>
                                <Address address={vote.participant} />
                              </div>
                              {vote.voteValue !== undefined && vote.isRevealed && (
                                <div>
                                  <p className="text-sm font-semibold">Vote Value:</p>
                                  <p className="text-lg font-bold">{vote.voteValue.toString()}</p>
                                </div>
                              )}
                              {vote.committedAt && (
                                <div>
                                  <p className="text-sm font-semibold">Committed:</p>
                                  <p className="text-sm">{formatTimestamp(vote.committedAt)}</p>
                                </div>
                              )}
                              {vote.revealedAt && (
                                <div>
                                  <p className="text-sm font-semibold">Revealed:</p>
                                  <p className="text-sm">{formatTimestamp(vote.revealedAt)}</p>
                                </div>
                              )}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* Participants Tab */}
              {activeTab === "participants" && (
                <div>
                  <h2 className="text-center text-3xl font-bold mb-6">Ceremony Participants</h2>
                  {scrumPokerData.ceremonyParticipants.items.length === 0 ? (
                    <div className="text-center">
                      <p className="text-xl opacity-70">No participants found</p>
                    </div>
                  ) : (
                    <div className="grid gap-4">
                      {scrumPokerData.ceremonyParticipants.items.map(participant => (
                        <div key={participant.id} className="card bg-base-100 shadow-xl">
                          <div className="card-body">
                            <div className="flex justify-between items-center">
                              <div>
                                <h3 className="card-title">
                                  <Address address={participant.participant} />
                                </h3>
                                <p className="text-sm opacity-70">Ceremony: {participant.ceremonyCode}</p>
                              </div>
                              <div>
                                <p className="text-sm font-semibold">Joined:</p>
                                <p className="text-sm">{formatTimestamp(participant.joinedAt)}</p>
                              </div>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </>
          )}
        </div>

        {/* Footer com informações técnicas */}
        <div className="w-full bg-base-200 px-8 py-4">
          <div className="text-center text-sm opacity-70">
            <p>
              Data indexed from ScrumPoker contracts on localhost:8545 •{" "}
              <Link href="http://localhost:42069" target="_blank" className="link">
                GraphQL Playground
              </Link>{" "}
              • Auto-refresh every 5 seconds
            </p>
          </div>
        </div>
      </div>
    </>
  );
};

export default ScrumPokerDashboard;
