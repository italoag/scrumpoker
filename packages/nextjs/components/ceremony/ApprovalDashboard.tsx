import { useState } from "react";
import { useAccount } from "wagmi";
import { 
  CheckIcon, 
  XMarkIcon, 
  ClockIcon,
  UserGroupIcon,
  ExclamationTriangleIcon
} from "@heroicons/react/24/outline";
import { Address } from "~~/components/scaffold-eth";
import { useScrumPokerContracts } from "~~/hooks/useScrumPokerContracts";

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

interface ApprovalDashboardProps {
  approvalRequests: CeremonyApprovalRequest[];
  ceremonies: Ceremony[];
  onRefresh: () => void;
}

export const ApprovalDashboard = ({ 
  approvalRequests, 
  ceremonies, 
  onRefresh 
}: ApprovalDashboardProps) => {
  const { address: connectedAddress } = useAccount();
  const contracts = useScrumPokerContracts();
  const [filter, setFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('pending');
  const [selectedCeremony, setSelectedCeremony] = useState<string>('all');

  // Filtrar cerimônias criadas pelo usuário conectado
  const userCeremonies = ceremonies.filter(c => c.creator === connectedAddress);
  
  // Filtrar solicitações por cerimônias do usuário e status
  const filteredRequests = approvalRequests.filter(request => {
    const ceremony = ceremonies.find(c => c.id === request.ceremonyCode);
    const isUserCeremony = ceremony?.creator === connectedAddress;
    const matchesStatus = filter === 'all' || request.status === filter;
    const matchesCeremony = selectedCeremony === 'all' || request.ceremonyCode === selectedCeremony;
    
    return isUserCeremony && matchesStatus && matchesCeremony;
  });

  const formatTimestamp = (timestamp: number) => {
    return new Date(timestamp * 1000).toLocaleString();
  };

  const getStatusBadge = (status: string) => {
    const statusConfig = {
      pending: { class: "badge-warning", icon: ClockIcon },
      approved: { class: "badge-success", icon: CheckIcon },
      rejected: { class: "badge-error", icon: XMarkIcon }
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

  const handleApprove = async (ceremonyCode: string, participant: string) => {
    try {
      await contracts.approveEntry(ceremonyCode, participant);
      // Refresh data after approval
      setTimeout(() => onRefresh(), 2000);
    } catch (error) {
      console.error('Failed to approve entry:', error);
    }
  };

  const pendingCount = filteredRequests.filter(r => r.status === 'pending').length;

  return (
    <div className="space-y-6">
      {/* Header with Stats */}
      <div className="stats shadow w-full">
        <div className="stat">
          <div className="stat-figure text-primary">
            <UserGroupIcon className="w-8 h-8" />
          </div>
          <div className="stat-title">Your Ceremonies</div>
          <div className="stat-value text-primary">{userCeremonies.length}</div>
          <div className="stat-desc">Created by you</div>
        </div>
        <div className="stat">
          <div className="stat-figure text-warning">
            <ClockIcon className="w-8 h-8" />
          </div>
          <div className="stat-title">Pending Approvals</div>
          <div className="stat-value text-warning">{pendingCount}</div>
          <div className="stat-desc">Awaiting your approval</div>
        </div>
        <div className="stat">
          <div className="stat-figure text-success">
            <CheckIcon className="w-8 h-8" />
          </div>
          <div className="stat-title">Total Requests</div>
          <div className="stat-value text-success">{filteredRequests.length}</div>
          <div className="stat-desc">All time</div>
        </div>
      </div>

      {/* Filters */}
      <div className="card bg-base-100 shadow-xl">
        <div className="card-body">
          <h3 className="card-title">Filters</h3>
          <div className="flex flex-wrap gap-4">
            {/* Status Filter */}
            <div className="form-control">
              <label className="label">
                <span className="label-text">Status</span>
              </label>
              <select 
                className="select select-bordered"
                value={filter}
                onChange={(e) => setFilter(e.target.value as any)}
              >
                <option value="all">All Status</option>
                <option value="pending">Pending</option>
                <option value="approved">Approved</option>
                <option value="rejected">Rejected</option>
              </select>
            </div>

            {/* Ceremony Filter */}
            <div className="form-control">
              <label className="label">
                <span className="label-text">Ceremony</span>
              </label>
              <select 
                className="select select-bordered"
                value={selectedCeremony}
                onChange={(e) => setSelectedCeremony(e.target.value)}
              >
                <option value="all">All Ceremonies</option>
                {userCeremonies.map(ceremony => (
                  <option key={ceremony.id} value={ceremony.id}>
                    {ceremony.title || ceremony.id}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-control">
              <label className="label">
                <span className="label-text">&nbsp;</span>
              </label>
              <button className="btn btn-outline" onClick={onRefresh}>
                Refresh
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Approval Requests */}
      {filteredRequests.length === 0 ? (
        <div className="card bg-base-100 shadow-xl">
          <div className="card-body text-center">
            <ExclamationTriangleIcon className="w-16 h-16 mx-auto text-gray-400 mb-4" />
            <h3 className="text-lg font-semibold">No approval requests found</h3>
            <p className="text-gray-600">
              {filter === 'pending' 
                ? "No pending approval requests for your ceremonies."
                : "No approval requests match your current filters."
              }
            </p>
          </div>
        </div>
      ) : (
        <div className="space-y-4">
          {filteredRequests.map(request => {
            const ceremony = ceremonies.find(c => c.id === request.ceremonyCode);
            
            return (
              <div key={request.id} className="card bg-base-100 shadow-xl">
                <div className="card-body">
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <h3 className="card-title">
                        Ceremony: {ceremony?.title || request.ceremonyCode}
                      </h3>
                      <div className="space-y-2">
                        <div className="flex items-center gap-2">
                          <span className="font-semibold">Participant:</span>
                          <Address address={request.participant} />
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="font-semibold">Status:</span>
                          {getStatusBadge(request.status)}
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="font-semibold">Requested:</span>
                          <span className="text-sm">{formatTimestamp(request.requestedAt)}</span>
                        </div>
                        {request.processedAt && (
                          <div className="flex items-center gap-2">
                            <span className="font-semibold">Processed:</span>
                            <span className="text-sm">{formatTimestamp(request.processedAt)}</span>
                          </div>
                        )}
                        {request.processedBy && (
                          <div className="flex items-center gap-2">
                            <span className="font-semibold">Processed by:</span>
                            <Address address={request.processedBy} />
                          </div>
                        )}
                      </div>
                    </div>
                    
                    {request.status === 'pending' && (
                      <div className="flex gap-2">
                        <button 
                          className="btn btn-success btn-sm"
                          onClick={() => handleApprove(request.ceremonyCode, request.participant)}
                          disabled={!connectedAddress}
                        >
                          <CheckIcon className="w-4 h-4" />
                          Approve
                        </button>
                        <button 
                          className="btn btn-error btn-sm"
                          disabled={!connectedAddress}
                        >
                          <XMarkIcon className="w-4 h-4" />
                          Reject
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};