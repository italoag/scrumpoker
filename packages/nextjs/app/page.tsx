"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { gql, request } from "graphql-request";
import type { NextPage } from "next";
import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { 
  PlusIcon, 
  PlayIcon, 
  StopIcon, 
  UserGroupIcon, 
  ChartBarIcon,
  ClockIcon,
  CheckCircleIcon,
  XCircleIcon,
  EyeIcon,
  EyeSlashIcon,
  CogIcon,
  DocumentTextIcon,
  TrophyIcon
} from "@heroicons/react/24/outline";
import { Address } from "~~/components/scaffold-eth";
import { useScrumPokerContracts } from "~~/hooks/useScrumPokerContracts";
import { ApprovalDashboard } from "~~/components/ceremony/ApprovalDashboard";


// Types for ScrumPoker data
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

type CeremonyApprovalRequest = {
  id: string;
  ceremonyCode: string;
  participant: `0x${string}`;
  status: string;
  requestedAt: number;
  processedAt?: number;
  processedBy?: `0x${string}`;
  blockNumber: bigint;
  transactionHash: `0x${string}`;
};

type ScrumPokerData = {
  ceremonys: { items: Ceremony[] };
  ceremonyParticipants: { items: CeremonyParticipant[] };
  functionalitySessions: { items: FunctionalitySession[] };
  functionalityVotes: { items: FunctionalityVote[] };
  ceremonyStatss: { items: CeremonyStats[] };
  ceremonyApprovalRequests: { items: CeremonyApprovalRequest[] };
};

const fetchScrumPokerData = async () => {
  if (typeof window === 'undefined') {
    return {
      ceremonys: { items: [] },
      ceremonyParticipants: { items: [] },
      functionalitySessions: { items: [] },
      functionalityVotes: { items: [] },
      ceremonyStatss: { items: [] },
      ceremonyApprovalRequests: { items: [] }
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
      ceremonyApprovalRequests(orderBy: "requestedAt", orderDirection: "desc") {
        items {
          id
          ceremonyCode
          participant
          status
          requestedAt
          processedAt
          processedBy
          blockNumber
          transactionHash
        }
      }
    }
  `;
  
  try {
    const data = await request<ScrumPokerData>(
      process.env.NEXT_PUBLIC_PONDER_URL || "http://localhost:42069",
      ScrumPokerQuery,
    );
    return data;
  } catch (error) {
    console.error("Failed to fetch ScrumPoker data from Ponder:", error);
    return {
      ceremonys: { items: [] },
      ceremonyParticipants: { items: [] },
      functionalitySessions: { items: [] },
      functionalityVotes: { items: [] },
      ceremonyStatss: { items: [] },
      ceremonyApprovalRequests: { items: [] }
    };
  }
};

const CeremonyManagementDashboard: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const [activeTab, setActiveTab] = useState<'dashboard' | 'create' | 'ceremonies' | 'voting' | 'participants' | 'nft' | 'admin' | 'approvals'>('dashboard');
  const [newCeremony, setNewCeremony] = useState({ title: '', description: '' });
  const [newFunctionality, setNewFunctionality] = useState({ ceremonyCode: '', functionalityCode: '' });
  const [voteData, setVoteData] = useState({ ceremonyCode: '', sessionIndex: '', voteValue: '' });
  const [participantData, setParticipantData] = useState({ ceremonyCode: '' });
  const contracts = useScrumPokerContracts();
  
  const { data: scrumPokerData, isLoading, error, refetch } = useQuery({
    queryKey: ["scrumPokerData"],
    queryFn: fetchScrumPokerData,
    refetchInterval: 3000,
  });

  const formatTimestamp = (timestamp: number) => {
    return new Date(timestamp * 1000).toLocaleString();
  };

  const getStatusBadge = (status: string) => {
    const statusConfig = {
      created: { class: "badge-info", icon: ClockIcon },
      started: { class: "badge-success", icon: PlayIcon },
      concluded: { class: "badge-neutral", icon: CheckCircleIcon },
      opened: { class: "badge-warning", icon: EyeIcon },
      closed: { class: "badge-error", icon: XCircleIcon }
    };
    const config = statusConfig[status as keyof typeof statusConfig] || { class: "badge-ghost", icon: ClockIcon };
    const IconComponent = config.icon;
    
    return (
      <div className={`badge ${config.class} gap-2`}>
        <IconComponent className="w-3 h-3" />
        {status}
      </div>
    );
  };

  const stats = scrumPokerData?.ceremonyStatss?.items?.[0];
  const userCeremonies = scrumPokerData?.ceremonys?.items?.filter(c => c.creator === connectedAddress) || [];
  const userParticipations = scrumPokerData?.ceremonyParticipants?.items?.filter(p => p.participant === connectedAddress) || [];

  // Form handlers
  const handleCreateCeremony = async () => {
    console.log("handleCreateCeremony called");
    console.log("newCeremony.title:", newCeremony.title);
    console.log("connectedAddress:", connectedAddress);
    console.log("contracts:", contracts);
    
    if (!newCeremony.title.trim()) {
      console.log("Title is empty, returning");
      return;
    }
    
    if (!connectedAddress) {
      console.log("No connected address, returning");
      return;
    }
    
    try {
      console.log("About to call startCeremony");
      // Start ceremony with a default sprint number (1)
      const result = await contracts.startCeremony(1);
      console.log("startCeremony result:", result);
      setNewCeremony({ title: '', description: '' });
      // Refresh data after successful creation
      setTimeout(() => refetch(), 2000);
    } catch (error) {
      console.error('Failed to create ceremony:', error);
    }
  };

  const handleStartCeremony = async (sprintNumber: number) => {
    try {
      await contracts.startCeremony(sprintNumber);
      // Refresh data after successful start
      setTimeout(() => refetch(), 2000);
    } catch (error) {
      console.error('Failed to start ceremony:', error);
    }
  };

  const handleConcludeCeremony = async (ceremonyCode: string) => {
    try {
      await contracts.concludeCeremony(ceremonyCode);
      // Refresh data after successful conclusion
      setTimeout(() => refetch(), 2000);
    } catch (error) {
      console.error('Failed to conclude ceremony:', error);
    }
  };

  const handleOpenSession = async () => {
    if (!newFunctionality.ceremonyCode.trim() || !newFunctionality.functionalityCode.trim()) {
      return;
    }
    
    try {
      await contracts.openFunctionalityVote(newFunctionality.ceremonyCode, newFunctionality.functionalityCode);
      setNewFunctionality({ ceremonyCode: '', functionalityCode: '' });
      // Refresh data after successful session opening
      setTimeout(() => refetch(), 2000);
    } catch (error) {
      console.error('Failed to open voting session:', error);
    }
  };

  const handleCommitVote = async () => {
    if (!voteData.ceremonyCode.trim() || !voteData.sessionIndex.trim() || !voteData.voteValue.trim()) {
      return;
    }
    
    try {
      // For functionality votes, we need to generate a commit hash
      const salt = Math.random().toString(36).substring(2, 15);
      const voteValue = parseInt(voteData.voteValue);
      
      // Create commit hash: keccak256(abi.encodePacked(voteValue, salt, msg.sender))
      const encoder = new TextEncoder();
      const data = encoder.encode(`${voteValue}${salt}${contracts.address}`);
      const hashBuffer = await crypto.subtle.digest('SHA-256', data);
      const hashArray = Array.from(new Uint8Array(hashBuffer));
      const commit = '0x' + hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
      
      // Store salt for later reveal (in real app, this should be stored securely)
      localStorage.setItem(`vote_salt_${voteData.ceremonyCode}_${voteData.sessionIndex}`, salt);
      
      await contracts.commitFunctionalityVote(
        voteData.ceremonyCode, 
        parseInt(voteData.sessionIndex), 
        commit
      );
      
      setVoteData({ ceremonyCode: '', sessionIndex: '', voteValue: '' });
      // Refresh data after successful vote commit
      setTimeout(() => refetch(), 2000);
    } catch (error) {
      console.error('Failed to commit vote:', error);
    }
  };

  const handleJoinCeremony = async () => {
    if (!participantData.ceremonyCode.trim()) {
      return;
    }
    
    try {
      await contracts.requestCeremonyEntry(participantData.ceremonyCode);
      setParticipantData({ ceremonyCode: '' });
      // Refresh data after successful join
      setTimeout(() => refetch(), 2000);
    } catch (error) {
      console.error('Failed to join ceremony:', error);
    }
  };

  return (
    <>
      <div className="min-h-screen bg-base-200">
        {/* Header */}
        <div className="navbar bg-base-100 shadow-lg">
          <div className="navbar-start">
            <h1 className="text-xl font-bold">ScrumPoker Ceremony Manager</h1>
          </div>
          <div className="navbar-center">
            {connectedAddress && (
              <div className="flex items-center gap-2">
                <span className="text-sm">Connected:</span>
                <Address address={connectedAddress} />
              </div>
            )}
          </div>
          <div className="navbar-end">
            <div className="dropdown dropdown-end">
              <label tabIndex={0} className="btn btn-ghost btn-circle">
                <CogIcon className="w-5 h-5" />
              </label>
              <ul tabIndex={0} className="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
                <li><Link href="/debug">Debug Contracts</Link></li>
                <li><Link href="/blockexplorer">Block Explorer</Link></li>
                <li><Link href="/dataview">Raw Data View</Link></li>
              </ul>
            </div>
          </div>
        </div>

        {/* Navigation Tabs */}
        <div className="tabs tabs-boxed justify-center mt-4 bg-transparent">
          <button 
            className={`tab tab-lg ${activeTab === 'dashboard' ? 'tab-active' : ''}`}
            onClick={() => setActiveTab('dashboard')}
          >
            <ChartBarIcon className="w-4 h-4 mr-2" />
            Dashboard
          </button>
          <button 
            className={`tab tab-lg ${activeTab === 'create' ? 'tab-active' : ''}`}
            onClick={() => setActiveTab('create')}
          >
            <PlusIcon className="w-4 h-4 mr-2" />
            Create
          </button>
          <button 
            className={`tab tab-lg ${activeTab === 'ceremonies' ? 'tab-active' : ''}`}
            onClick={() => setActiveTab('ceremonies')}
          >
            <DocumentTextIcon className="w-4 h-4 mr-2" />
            Ceremonies
          </button>
          <button 
            className={`tab tab-lg ${activeTab === 'voting' ? 'tab-active' : ''}`}
            onClick={() => setActiveTab('voting')}
          >
            <CheckCircleIcon className="w-4 h-4 mr-2" />
            Voting
          </button>
          <button 
            className={`tab tab-lg ${activeTab === 'participants' ? 'tab-active' : ''}`}
            onClick={() => setActiveTab('participants')}
          >
            <UserGroupIcon className="w-4 h-4 mr-2" />
            Participants
          </button>
          <button 
            className={`tab tab-lg ${activeTab === 'nft' ? 'tab-active' : ''}`}
            onClick={() => setActiveTab('nft')}
          >
            <TrophyIcon className="w-4 h-4 mr-2" />
            NFT
          </button>
          <button 
            className={`tab tab-lg ${activeTab === 'admin' ? 'tab-active' : ''}`}
            onClick={() => setActiveTab('admin')}
          >
            <CogIcon className="w-4 h-4 mr-2" />
            Admin
          </button>
          <button 
            className={`tab tab-lg ${activeTab === 'approvals' ? 'tab-active' : ''}`}
            onClick={() => setActiveTab('approvals')}
          >
            <CheckCircleIcon className="w-4 h-4 mr-2" />
            Approvals
          </button>
        </div>

        {/* Main Content */}
        <div className="container mx-auto px-4 py-8">
          {isLoading && (
            <div className="flex items-center justify-center h-64">
              <div className="loading loading-dots loading-lg"></div>
              <span className="ml-4">Loading ceremony data...</span>
            </div>
          )}

          {error && (
            <div className="alert alert-error mb-6">
              <span>Failed to load data. Make sure Ponder server is running on port 42069.</span>
              <button className="btn btn-sm" onClick={() => refetch()}>Retry</button>
            </div>
          )}

          {!connectedAddress && (
            <div className="alert alert-warning mb-6">
              <span>Please connect your wallet to access ceremony management features.</span>
            </div>
          )}

          {/* Dashboard Tab */}
          {activeTab === 'dashboard' && (
            <div className="space-y-6">
              {/* Stats Overview */}
              {stats && (
                <div className="stats shadow w-full">
                  <div className="stat">
                    <div className="stat-figure text-primary">
                      <DocumentTextIcon className="w-8 h-8" />
                    </div>
                    <div className="stat-title">Total Ceremonies</div>
                    <div className="stat-value text-primary">{stats.totalCeremonies.toString()}</div>
                    <div className="stat-desc">Your ceremonies: {userCeremonies.length}</div>
                  </div>
                  <div className="stat">
                    <div className="stat-figure text-secondary">
                      <UserGroupIcon className="w-8 h-8" />
                    </div>
                    <div className="stat-title">Total Participants</div>
                    <div className="stat-value text-secondary">{stats.totalParticipants.toString()}</div>
                    <div className="stat-desc">Your participations: {userParticipations.length}</div>
                  </div>
                  <div className="stat">
                    <div className="stat-figure text-accent">
                      <CheckCircleIcon className="w-8 h-8" />
                    </div>
                    <div className="stat-title">Total Votes</div>
                    <div className="stat-value text-accent">{stats.totalVotes.toString()}</div>
                    <div className="stat-desc">Last updated: {formatTimestamp(stats.lastUpdated)}</div>
                  </div>
                </div>
              )}

              {/* Quick Actions */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <button 
                  className="btn btn-primary btn-lg"
                  onClick={() => setActiveTab('create')}
                  disabled={!connectedAddress}
                >
                  <PlusIcon className="w-6 h-6" />
                  Create Ceremony
                </button>
                <button 
                  className="btn btn-secondary btn-lg"
                  onClick={() => setActiveTab('voting')}
                  disabled={!connectedAddress}
                >
                  <CheckCircleIcon className="w-6 h-6" />
                  Vote Now
                </button>
                <button 
                  className="btn btn-accent btn-lg"
                  onClick={() => setActiveTab('participants')}
                  disabled={!connectedAddress}
                >
                  <UserGroupIcon className="w-6 h-6" />
                  Join Ceremony
                </button>
                <button 
                  className="btn btn-info btn-lg"
                  onClick={() => setActiveTab('nft')}
                  disabled={!connectedAddress}
                >
                  <TrophyIcon className="w-6 h-6" />
                  Mint NFT
                </button>
              </div>

              {/* Recent Activity */}
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div className="card bg-base-100 shadow-xl">
                  <div className="card-body">
                    <h3 className="card-title">Recent Ceremonies</h3>
                    {scrumPokerData?.ceremonys?.items?.slice(0, 5).map((ceremony) => (
                      <div key={ceremony.id} className="flex items-center justify-between border-b pb-2 last:border-b-0">
                        <div>
                          <p className="font-semibold">{ceremony.title}</p>
                          <p className="text-sm opacity-70">{ceremony.id}</p>
                        </div>
                        <div className="text-right">
                          {getStatusBadge(ceremony.status)}
                          <p className="text-xs mt-1">{formatTimestamp(ceremony.createdAt)}</p>
                        </div>
                      </div>
                    )) || <p className="text-center opacity-70">No ceremonies found</p>}
                  </div>
                </div>

                <div className="card bg-base-100 shadow-xl">
                  <div className="card-body">
                    <h3 className="card-title">Active Voting Sessions</h3>
                    {scrumPokerData?.functionalitySessions?.items
                      ?.filter(s => s.status === 'opened')
                      ?.slice(0, 5)
                      .map((session) => (
                      <div key={session.id} className="flex items-center justify-between border-b pb-2 last:border-b-0">
                        <div>
                          <p className="font-semibold">{session.functionalityCode}</p>
                          <p className="text-sm opacity-70">Session #{session.sessionIndex.toString()}</p>
                        </div>
                        <div className="text-right">
                          {getStatusBadge(session.status)}
                          <p className="text-xs mt-1">{formatTimestamp(session.openedAt)}</p>
                        </div>
                      </div>
                    )) || <p className="text-center opacity-70">No active sessions</p>}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Create Tab */}
          {activeTab === 'create' && (
            <div className="max-w-2xl mx-auto">
              <div className="card bg-base-100 shadow-xl">
                <div className="card-body">
                  <h2 className="card-title text-2xl mb-6">Create New Ceremony</h2>
                  
                  <div className="form-control w-full">
                    <label className="label">
                      <span className="label-text">Ceremony Title</span>
                    </label>
                    <input 
                      type="text" 
                      placeholder="Enter ceremony title" 
                      className="input input-bordered w-full"
                      value={newCeremony.title}
                      onChange={(e) => setNewCeremony({...newCeremony, title: e.target.value})}
                    />
                  </div>

                  <div className="form-control w-full">
                    <label className="label">
                      <span className="label-text">Description (Optional)</span>
                    </label>
                    <textarea 
                      className="textarea textarea-bordered h-24" 
                      placeholder="Enter ceremony description"
                      value={newCeremony.description}
                      onChange={(e) => setNewCeremony({...newCeremony, description: e.target.value})}
                    ></textarea>
                  </div>

                  <div className="card-actions justify-end mt-6">
                    <button 
                      className="btn btn-primary"
                      onClick={handleCreateCeremony}
                      disabled={!connectedAddress || !newCeremony.title}
                    >
                      <PlusIcon className="w-4 h-4 mr-2" />
                      Create Ceremony
                    </button>
                  </div>
                </div>
              </div>

              {/* Create Voting Session */}
              <div className="card bg-base-100 shadow-xl mt-6">
                <div className="card-body">
                  <h2 className="card-title text-2xl mb-6">Open Voting Session</h2>
                  
                  <div className="form-control w-full">
                    <label className="label">
                      <span className="label-text">Ceremony Code</span>
                    </label>
                    <input 
                      type="text" 
                      placeholder="Enter ceremony code" 
                      className="input input-bordered w-full"
                      value={newFunctionality.ceremonyCode}
                      onChange={(e) => setNewFunctionality({...newFunctionality, ceremonyCode: e.target.value})}
                    />
                  </div>

                  <div className="form-control w-full">
                    <label className="label">
                      <span className="label-text">Functionality Code</span>
                    </label>
                    <input 
                      type="text" 
                      placeholder="Enter functionality to vote on" 
                      className="input input-bordered w-full"
                      value={newFunctionality.functionalityCode}
                      onChange={(e) => setNewFunctionality({...newFunctionality, functionalityCode: e.target.value})}
                    />
                  </div>

                  <div className="card-actions justify-end mt-6">
                    <button 
                      className="btn btn-secondary"
                      onClick={handleOpenSession}
                      disabled={!connectedAddress || !newFunctionality.ceremonyCode || !newFunctionality.functionalityCode}
                    >
                      <PlayIcon className="w-4 h-4 mr-2" />
                      Open Session
                    </button>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Ceremonies Tab */}
          {activeTab === 'ceremonies' && (
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <h2 className="text-3xl font-bold">All Ceremonies</h2>
                <div className="flex gap-2">
                  <button className="btn btn-outline" onClick={() => refetch()}>
                    Refresh
                  </button>
                </div>
              </div>

              {scrumPokerData?.ceremonys?.items?.length === 0 ? (
                <div className="text-center py-12">
                  <DocumentTextIcon className="w-16 h-16 mx-auto opacity-50 mb-4" />
                  <p className="text-xl opacity-70">No ceremonies found</p>
                  <p className="mt-2">Create your first ceremony to get started!</p>
                  <button 
                    className="btn btn-primary mt-4"
                    onClick={() => setActiveTab('create')}
                  >
                    Create Ceremony
                  </button>
                </div>
              ) : (
                <div className="grid gap-4">
                  {scrumPokerData?.ceremonys?.items?.map((ceremony) => (
                    <div key={ceremony.id} className="card bg-base-100 shadow-xl">
                      <div className="card-body">
                        <div className="flex justify-between items-start">
                          <div className="flex-1">
                            <h3 className="card-title text-xl">{ceremony.title}</h3>
                            <p className="text-sm opacity-70 mb-2">Code: {ceremony.id}</p>
                            {ceremony.description && <p className="mb-4">{ceremony.description}</p>}
                            
                            <div className="grid grid-cols-2 gap-4">
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
                          
                          <div className="flex flex-col items-end gap-2">
                            {getStatusBadge(ceremony.status)}
                            
                            {connectedAddress === ceremony.creator && (
                              <div className="flex gap-2">
                                {ceremony.status === 'created' && (
                                  <button 
                                    className="btn btn-sm btn-success"
                                    onClick={() => handleStartCeremony(1)}
                                  >
                                    <PlayIcon className="w-3 h-3" />
                                    Start
                                  </button>
                                )}
                                {ceremony.status === 'started' && (
                                  <button 
                                    className="btn btn-sm btn-warning"
                                    onClick={() => handleConcludeCeremony(ceremony.id)}
                                  >
                                    <StopIcon className="w-3 h-3" />
                                    Conclude
                                  </button>
                                )}
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Voting Tab */}
          {activeTab === 'voting' && (
            <div className="space-y-6">
              {/* Vote Form */}
              <div className="card bg-base-100 shadow-xl max-w-2xl mx-auto">
                <div className="card-body">
                  <h2 className="card-title text-2xl mb-6">Submit Vote</h2>
                  
                  <div className="form-control w-full">
                    <label className="label">
                      <span className="label-text">Ceremony Code</span>
                    </label>
                    <input 
                      type="text" 
                      placeholder="Enter ceremony code" 
                      className="input input-bordered w-full"
                      value={voteData.ceremonyCode}
                      onChange={(e) => setVoteData({...voteData, ceremonyCode: e.target.value})}
                    />
                  </div>

                  <div className="form-control w-full">
                    <label className="label">
                      <span className="label-text">Session Index</span>
                    </label>
                    <input 
                      type="number" 
                      placeholder="Enter session index" 
                      className="input input-bordered w-full"
                      value={voteData.sessionIndex}
                      onChange={(e) => setVoteData({...voteData, sessionIndex: e.target.value})}
                    />
                  </div>

                  <div className="form-control w-full">
                    <label className="label">
                      <span className="label-text">Vote Value (Story Points)</span>
                    </label>
                    <div className="grid grid-cols-4 gap-2">
                      {[1, 2, 3, 5, 8, 13, 21, 34].map((value) => (
                        <button
                          key={value}
                          className={`btn ${voteData.voteValue === value.toString() ? 'btn-primary' : 'btn-outline'}`}
                          onClick={() => setVoteData({...voteData, voteValue: value.toString()})}
                        >
                          {value}
                        </button>
                      ))}
                    </div>
                  </div>

                  <div className="card-actions justify-end mt-6">
                    <button 
                      className="btn btn-primary"
                      onClick={handleCommitVote}
                      disabled={!connectedAddress || !voteData.ceremonyCode || !voteData.sessionIndex || !voteData.voteValue}
                    >
                      <CheckCircleIcon className="w-4 h-4 mr-2" />
                      Commit Vote
                    </button>
                  </div>
                </div>
              </div>

              {/* Active Sessions */}
              <div>
                <h3 className="text-2xl font-bold mb-4">Active Voting Sessions</h3>
                {scrumPokerData?.functionalitySessions?.items
                  ?.filter(s => s.status === 'opened')
                  ?.map((session) => (
                  <div key={session.id} className="card bg-base-100 shadow-xl mb-4">
                    <div className="card-body">
                      <div className="flex justify-between items-start">
                        <div>
                          <h4 className="card-title">{session.functionalityCode}</h4>
                          <p className="text-sm opacity-70">Session #{session.sessionIndex.toString()}</p>
                          <p className="text-sm opacity-70">Ceremony: {session.ceremonyCode}</p>
                        </div>
                        <div className="text-right">
                          {getStatusBadge(session.status)}
                          <p className="text-xs mt-1">{formatTimestamp(session.openedAt)}</p>
                        </div>
                      </div>
                      
                      <div className="card-actions justify-end mt-4">
                        <button 
                          className="btn btn-primary btn-sm"
                          onClick={() => {
                            setVoteData({
                              ceremonyCode: session.ceremonyCode,
                              sessionIndex: session.sessionIndex.toString(),
                              voteValue: ''
                            });
                          }}
                        >
                          Vote on This Session
                        </button>
                        <button 
                          className="btn btn-secondary btn-sm"
                          onClick={async () => {
                            const salt = localStorage.getItem(`vote_salt_${session.ceremonyCode}_${session.sessionIndex}`);
                            if (salt && voteData.voteValue) {
                              try {
                                await contracts.revealFunctionalityVote(
                                  session.ceremonyCode,
                                  Number(session.sessionIndex),
                                  parseInt(voteData.voteValue),
                                  salt
                                );
                                localStorage.removeItem(`vote_salt_${session.ceremonyCode}_${session.sessionIndex}`);
                              } catch (error) {
                                console.error('Failed to reveal vote:', error);
                              }
                            }
                          }}
                        >
                          Reveal Vote
                        </button>
                      </div>
                    </div>
                  </div>
                )) || <p className="text-center opacity-70">No active voting sessions</p>}
              </div>

              {/* Recent Votes */}
              <div>
                <h3 className="text-2xl font-bold mb-4">Recent Votes</h3>
                <div className="grid gap-4">
                  {scrumPokerData?.functionalityVotes?.items?.slice(0, 10).map((vote) => (
                    <div key={vote.id} className="card bg-base-100 shadow-xl">
                      <div className="card-body">
                        <div className="flex justify-between items-start">
                          <div>
                            <h4 className="card-title">Session #{vote.sessionIndex.toString()}</h4>
                            <p className="text-sm opacity-70">Ceremony: {vote.ceremonyCode}</p>
                            <Address address={vote.participant} />
                          </div>
                          <div className="text-right">
                            <div className="flex gap-2 mb-2">
                              {vote.isCommitted && <div className="badge badge-info">Committed</div>}
                              {vote.isRevealed && <div className="badge badge-success">Revealed</div>}
                            </div>
                            {vote.voteValue !== undefined && vote.isRevealed && (
                              <div className="text-2xl font-bold">{vote.voteValue.toString()}</div>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  )) || <p className="text-center opacity-70">No votes found</p>}
                </div>
              </div>
            </div>
          )}

          {/* Participants Tab */}
          {activeTab === 'participants' && (
            <div className="space-y-6">
              {/* Join Ceremony Form */}
              <div className="card bg-base-100 shadow-xl max-w-2xl mx-auto">
                <div className="card-body">
                  <h2 className="card-title text-2xl mb-6">Join Ceremony</h2>
                  
                  <div className="form-control w-full">
                    <label className="label">
                      <span className="label-text">Ceremony Code</span>
                    </label>
                    <input 
                      type="text" 
                      placeholder="Enter ceremony code to join" 
                      className="input input-bordered w-full"
                      value={participantData.ceremonyCode}
                      onChange={(e) => setParticipantData({...participantData, ceremonyCode: e.target.value})}
                    />
                  </div>

                  <div className="card-actions justify-end mt-6">
                    <button 
                      className="btn btn-primary"
                      onClick={handleJoinCeremony}
                      disabled={!connectedAddress || !participantData.ceremonyCode}
                    >
                      <UserGroupIcon className="w-4 h-4 mr-2" />
                      Join Ceremony
                    </button>
                  </div>
                </div>
              </div>

              {/* Participants List */}
              <div>
                <h3 className="text-2xl font-bold mb-4">All Participants</h3>
                <div className="grid gap-4">
                  {scrumPokerData?.ceremonyParticipants?.items?.map((participant) => (
                    <div key={participant.id} className="card bg-base-100 shadow-xl">
                      <div className="card-body">
                        <div className="flex justify-between items-center">
                          <div>
                            <Address address={participant.participant} />
                            <p className="text-sm opacity-70">Ceremony: {participant.ceremonyCode}</p>
                          </div>
                          <div className="text-right">
                            <p className="text-sm">Joined: {formatTimestamp(participant.joinedAt)}</p>
                          </div>
                        </div>
                      </div>
                    </div>
                  )) || <p className="text-center opacity-70">No participants found</p>}
                </div>
              </div>
            </div>
          )}

          {/* NFT Tab */}
          {activeTab === 'nft' && (
            <div className="space-y-6">
              <div className="text-center">
                <TrophyIcon className="w-16 h-16 mx-auto mb-4" />
                <h2 className="text-3xl font-bold mb-4">NFT Rewards</h2>
                <p className="text-lg opacity-70 mb-8">Mint NFTs for ceremony participation and achievements</p>
              </div>

              {/* User NFT Status */}
              {connectedAddress && (
                <div className="card bg-base-100 shadow-xl">
                  <div className="card-body">
                    <h3 className="card-title">Your NFT Status</h3>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      <div className="stat">
                        <div className="stat-title">NFT Balance</div>
                        <div className="stat-value">{contracts.nftBalance?.toString() || '0'}</div>
                      </div>
                      <div className="stat">
                        <div className="stat-title">Token ID</div>
                        <div className="stat-value">{contracts.userToken?.toString() || 'None'}</div>
                      </div>
                      <div className="stat">
                        <div className="stat-title">Vesting Status</div>
                        <div className={`stat-value ${contracts.isVested ? 'text-success' : 'text-warning'}`}>
                          {contracts.userToken ? 
                            (contracts.isVested ? 'Vested' : 'Pending') : 
                            'No NFT'
                          }
                        </div>
                        {contracts.userToken && !contracts.isVested && contracts.vestingPeriod && (
                          <div className="stat-desc text-xs">
                            Vesting period: {Math.floor(Number(contracts.vestingPeriod) / 86400)} days
                          </div>
                        )}
                      </div>
                    </div>
                    
                    {contracts.exchangeRate && (
                      <div className="mt-4">
                        <p className="text-sm opacity-70">
                          NFT Price: {(Number(contracts.exchangeRate) / 1e18).toFixed(4)} ETH
                        </p>
                      </div>
                    )}
                  </div>
                </div>
              )}

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <div className="card bg-base-100 shadow-xl">
                  <div className="card-body text-center">
                    <TrophyIcon className="w-12 h-12 mx-auto mb-4 text-primary" />
                    <h3 className="card-title justify-center">Ceremony Creator</h3>
                    <p>Mint NFT for creating ceremonies and managing scrum poker sessions</p>
                    <div className="card-actions justify-center mt-4">
                      <button 
                        className="btn btn-primary" 
                        disabled={!connectedAddress || !contracts.exchangeRate}
                        onClick={() => contracts.purchaseNFT("Ceremony Creator", "https://example.com/creator-nft")}
                      >
                        Mint Creator NFT
                      </button>
                    </div>
                  </div>
                </div>

                <div className="card bg-base-100 shadow-xl">
                  <div className="card-body text-center">
                    <UserGroupIcon className="w-12 h-12 mx-auto mb-4 text-secondary" />
                    <h3 className="card-title justify-center">Active Participant</h3>
                    <p>Mint NFT for participating in ceremonies and voting sessions</p>
                    <div className="card-actions justify-center mt-4">
                      <button 
                        className="btn btn-secondary" 
                        disabled={!connectedAddress || !contracts.exchangeRate}
                        onClick={() => contracts.purchaseNFT("Active Participant", "https://example.com/participant-nft")}
                      >
                        Mint Participant NFT
                      </button>
                    </div>
                  </div>
                </div>

                <div className="card bg-base-100 shadow-xl">
                  <div className="card-body text-center">
                    <CheckCircleIcon className="w-12 h-12 mx-auto mb-4 text-accent" />
                    <h3 className="card-title justify-center">Voting Champion</h3>
                    <p>Mint NFT for consistent voting and engagement</p>
                    <div className="card-actions justify-center mt-4">
                      <button 
                        className="btn btn-accent" 
                        disabled={!connectedAddress || !contracts.exchangeRate}
                        onClick={() => contracts.purchaseNFT("Voting Champion", "https://example.com/voter-nft")}
                      >
                        Mint Voter NFT
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              {/* NFT Management */}
              {contracts.userToken && contracts.userToken > 0 && (
                <div className="card bg-base-100 shadow-xl">
                  <div className="card-body">
                    <h3 className="card-title">NFT Management</h3>
                    <p className="opacity-70 mb-4">
                      You own NFT #{contracts.userToken.toString()}. 
                      {!contracts.isVested && " Your NFT is still in vesting period."}
                    </p>
                    
                    <div className="flex gap-4">
                      <button 
                        className="btn btn-outline"
                        onClick={() => window.open(`https://opensea.io/assets/ethereum/${contracts.address}/${contracts.userToken}`, '_blank')}
                      >
                        View on OpenSea
                      </button>
                      
                      {!contracts.isVested && (
                        <button 
                          className="btn btn-warning"
                          onClick={() => contracts.refundNFT()}
                        >
                          Refund NFT
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              )}

              {/* NFT Collection Display */}
              <div className="card bg-base-100 shadow-xl">
                <div className="card-body">
                  <h3 className="card-title">Your NFT Collection</h3>
                  {contracts.nftBalance && contracts.nftBalance > 0 ? (
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
                      {Array.from({ length: Number(contracts.nftBalance) }, (_, i) => (
                        <div key={i} className="card bg-base-200 shadow">
                          <div className="card-body text-center">
                            <TrophyIcon className="w-16 h-16 mx-auto mb-2 text-primary" />
                            <h4 className="card-title text-sm justify-center">NFT #{contracts.userToken?.toString()}</h4>
                            <p className="text-xs opacity-70">ScrumPoker Badge</p>
                            <div className="badge badge-sm badge-primary mt-2">
                              {contracts.isVested ? 'Vested' : 'Vesting'}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="text-center py-8">
                      <TrophyIcon className="w-16 h-16 mx-auto opacity-50 mb-4" />
                      <p className="text-lg opacity-70">No NFTs owned</p>
                      <p className="text-sm opacity-50">Purchase your first NFT to get started!</p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* Admin Tab */}
          {activeTab === 'admin' && (
            <div className="space-y-6">
              <div className="text-center">
                <CogIcon className="w-16 h-16 mx-auto mb-4" />
                <h2 className="text-3xl font-bold mb-4">Administrative Functions</h2>
                <p className="text-lg opacity-70 mb-8">Manage system settings and configurations</p>
              </div>

              {/* System Status */}
              <div className="card bg-base-100 shadow-xl">
                <div className="card-body">
                  <h3 className="card-title">System Status</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                    <div className="stat">
                      <div className="stat-title">Contract Status</div>
                      <div className={`stat-value ${contracts.isPaused ? 'text-error' : 'text-success'}`}>
                        {contracts.isPaused ? 'Paused' : 'Active'}
                      </div>
                    </div>
                    <div className="stat">
                      <div className="stat-title">Exchange Rate</div>
                      <div className="stat-value text-sm">
                        {contracts.exchangeRate ? `${(Number(contracts.exchangeRate) / 1e18).toFixed(4)} ETH` : 'Loading...'}
                      </div>
                    </div>
                    <div className="stat">
                      <div className="stat-title">Vesting Period</div>
                      <div className="stat-value text-sm">
                        {contracts.vestingPeriod ? `${Number(contracts.vestingPeriod) / 86400} days` : 'Loading...'}
                      </div>
                    </div>
                    <div className="stat">
                      <div className="stat-title">Your NFT</div>
                      <div className="stat-value text-sm">
                        {contracts.userToken ? `#${contracts.userToken.toString()}` : 'None'}
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Contract Management */}
                <div className="card bg-base-100 shadow-xl">
                  <div className="card-body">
                    <h3 className="card-title">Contract Management</h3>
                    <div className="space-y-4">
                      <div className="flex gap-2">
                        <button 
                          className="btn btn-warning flex-1"
                          onClick={() => contracts.pauseContract()}
                          disabled={!connectedAddress || contracts.isPaused}
                        >
                          Pause Contract
                        </button>
                        <button 
                          className="btn btn-success flex-1"
                          onClick={() => contracts.unpauseContract()}
                          disabled={!connectedAddress || !contracts.isPaused}
                        >
                          Unpause Contract
                        </button>
                      </div>
                      
                      <Link href="/debug" className="btn btn-outline w-full">
                        Debug Contracts
                      </Link>
                      
                      <button className="btn btn-outline w-full">
                        Verify Contracts
                      </button>
                    </div>
                  </div>
                </div>

                {/* Exchange Rate Management */}
                <div className="card bg-base-100 shadow-xl">
                  <div className="card-body">
                    <h3 className="card-title">Exchange Rate Management</h3>
                    <div className="space-y-4">
                      <div className="form-control">
                        <label className="label">
                          <span className="label-text">New Exchange Rate (wei)</span>
                        </label>
                        <input 
                          type="text" 
                          className="input input-bordered" 
                          placeholder="Enter new rate in wei"
                          id="newExchangeRate"
                        />
                      </div>
                      
                      <button 
                        className="btn btn-primary w-full"
                        onClick={() => {
                          const input = document.getElementById('newExchangeRate') as HTMLInputElement;
                          if (input.value) {
                            contracts.updateExchangeRate(input.value);
                            input.value = '';
                          }
                        }}
                        disabled={!connectedAddress}
                      >
                        Update Exchange Rate
                      </button>
                      
                      <div className="divider">Current Rate</div>
                      <div className="text-center">
                        <p className="text-2xl font-bold">
                          {contracts.exchangeRate ? `${(Number(contracts.exchangeRate) / 1e18).toFixed(4)} ETH` : 'Loading...'}
                        </p>
                        <p className="text-sm opacity-70">per NFT</p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Role Management */}
                <div className="card bg-base-100 shadow-xl">
                  <div className="card-body">
                    <h3 className="card-title">Role Management</h3>
                    <div className="space-y-4">
                      <div className="form-control">
                        <label className="label">
                          <span className="label-text">Address</span>
                        </label>
                        <input 
                          type="text" 
                          className="input input-bordered" 
                          placeholder="0x..."
                          id="roleAddress"
                        />
                      </div>
                      
                      <div className="form-control">
                        <label className="label">
                          <span className="label-text">Role</span>
                        </label>
                        <select className="select select-bordered" id="roleSelect">
                          <option value="">Select role</option>
                          <option value="0x0000000000000000000000000000000000000000000000000000000000000000">ADMIN_ROLE</option>
                          <option value="0x1234567890123456789012345678901234567890123456789012345678901234">PRICE_UPDATER_ROLE</option>
                        </select>
                      </div>
                      
                      <div className="flex gap-2">
                        <button 
                          className="btn btn-success flex-1"
                          onClick={() => {
                            const addressInput = document.getElementById('roleAddress') as HTMLInputElement;
                            const roleSelect = document.getElementById('roleSelect') as HTMLSelectElement;
                            if (addressInput.value && roleSelect.value) {
                              contracts.grantRole(roleSelect.value, addressInput.value);
                              addressInput.value = '';
                              roleSelect.value = '';
                            }
                          }}
                          disabled={!connectedAddress}
                        >
                          Grant Role
                        </button>
                        <button 
                          className="btn btn-error flex-1"
                          onClick={() => {
                            const addressInput = document.getElementById('roleAddress') as HTMLInputElement;
                            const roleSelect = document.getElementById('roleSelect') as HTMLSelectElement;
                            if (addressInput.value && roleSelect.value) {
                              contracts.revokeRole(roleSelect.value, addressInput.value);
                              addressInput.value = '';
                              roleSelect.value = '';
                            }
                          }}
                          disabled={!connectedAddress}
                        >
                          Revoke Role
                        </button>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Data Management */}
                <div className="card bg-base-100 shadow-xl">
                  <div className="card-body">
                    <h3 className="card-title">Data Management</h3>
                    <div className="space-y-4">
                      <button className="btn btn-outline w-full" onClick={() => refetch()}>
                        Refresh All Data
                      </button>
                      
                      <button 
                        className="btn btn-outline w-full"
                        onClick={() => {
                          const data = JSON.stringify(scrumPokerData, null, 2);
                          const blob = new Blob([data], { type: 'application/json' });
                          const url = URL.createObjectURL(blob);
                          const a = document.createElement('a');
                          a.href = url;
                          a.download = 'scrumpoker-data.json';
                          a.click();
                          URL.revokeObjectURL(url);
                        }}
                      >
                        Export Data
                      </button>
                      
                      <button 
                        className="btn btn-warning w-full"
                        onClick={() => {
                          localStorage.clear();
                          window.location.reload();
                        }}
                      >
                        Clear Cache
                      </button>
                      
                      <div className="divider">Network Info</div>
                      <div className="text-sm space-y-1">
                        <div className="flex justify-between">
                          <span>Ponder URL:</span>
                          <span className="text-right">{process.env.NEXT_PUBLIC_PONDER_URL || "http://localhost:42069"}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Network:</span>
                          <span>localhost:8545</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Last Update:</span>
                          <span>{stats ? formatTimestamp(stats.lastUpdated) : 'N/A'}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Approvals Tab */}
          {activeTab === 'approvals' && (
            <div className="space-y-6">
              <div className="text-center">
                <h2 className="text-3xl font-bold">Ceremony Approval Dashboard</h2>
                <p className="text-gray-600 mt-2">
                  Manage participation requests for your ceremonies
                </p>
              </div>

              {!connectedAddress ? (
                <div className="alert alert-warning">
                  <span>Please connect your wallet to access the approval dashboard.</span>
                </div>
              ) : (
                <ApprovalDashboard 
                  approvalRequests={scrumPokerData?.ceremonyApprovalRequests?.items || []}
                  ceremonies={scrumPokerData?.ceremonys?.items || []}
                  onRefresh={refetch}
                />
              )}
            </div>
          )}
        </div>
      </div>
    </>
  );
};

export default CeremonyManagementDashboard;