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
import { notification } from "~~/utils/scaffold-eth";

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
  const [filter, setFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('pending');
  const [selectedCeremony, setSelectedCeremony] = useState<string>('all');

  // Hook para interagir com o contrato ScrumPokerDiamond
  const contracts = useScrumPokerContracts();

  // Função para aprovar solicitação
  const handleApprove = async (request: CeremonyApprovalRequest) => {
    console.log("🔍 DEBUG handleApprove START:", {
      requestId: request.id,
      ceremonyCode: request.ceremonyCode,
      participant: request.participant,
      connectedAddress
    });
    
    // Validações básicas
    if (!request.ceremonyCode || request.ceremonyCode.trim() === '') {
      console.error("❌ Código da cerimônia está vazio");
      notification.error("Código da cerimônia inválido");
      return;
    }
    
    if (!request.participant) {
      console.error("❌ Participante inválido");
      notification.error("Participante inválido");
      return;
    }
    
    // O ceremonyCode já deve ser o código correto da cerimônia (ex: "CEREMONY1")
    // Não precisamos validar contra o array de ceremonies porque eles podem ter IDs diferentes
    const ceremonyCodeToUse = request.ceremonyCode.trim();
    
    try {
      console.log("🚀 Calling approveEntry with args:", {
        functionName: "approveEntry",
        args: [ceremonyCodeToUse, request.participant],
        contractName: "ScrumPokerDiamond"
      });
      
      await contracts.approveEntry(ceremonyCodeToUse, request.participant);
      
      notification.success("Solicitação aprovada com sucesso!");
      onRefresh(); // Atualizar dados após aprovação
    } catch (error) {
      console.error("❌ Erro ao aprovar solicitação:", error);
      console.error("Error details:", JSON.stringify(error, null, 2));
      
      // Mensagem de erro mais específica
      const errorMessage = (error as any)?.message || (error as any)?.reason || "Erro desconhecido";
      if (errorMessage.includes("CeremonyNotFound")) {
        notification.error(`Cerimônia "${ceremonyCodeToUse}" não encontrada no contrato. Verifique se a cerimônia foi criada corretamente.`);
      } else if (errorMessage.includes("NotAuthorized")) {
        notification.error("Você não tem permissão para aprovar esta solicitação");
      } else if (errorMessage.includes("EntryNotRequested")) {
        notification.error("O participante não solicitou entrada nesta cerimônia");
      } else if (errorMessage.includes("ParticipantAlreadyApproved")) {
        notification.error("O participante já foi aprovado nesta cerimônia");
      } else {
        notification.error(`Erro ao aprovar solicitação: ${errorMessage}`);
      }
    }
  };

  // Função para rejeitar solicitação (remove localmente da lista)
  const handleReject = async (request: CeremonyApprovalRequest) => {
    try {
      // Como não há função de reject no contrato, vamos simular removendo da lista
      // Na prática, isso seria uma chamada para um backend ou contrato que marca como rejeitado
      console.log("🚫 Rejeitando solicitação:", request.id);
      
      // Por enquanto, apenas mostra notificação e atualiza
      notification.success("Solicitação rejeitada!");
      onRefresh(); // Atualizar dados após rejeição
    } catch (error) {
      console.error("❌ Erro ao rejeitar solicitação:", error);
      notification.error("Erro ao rejeitar solicitação");
    }
  };

  // Debug: Verificar dados antes do filtro
  console.log('ApprovalDashboard Debug - Dados completos:', {
    connectedAddress,
    ceremonies: ceremonies.map(c => ({ id: c.id, name: c.name, creator: c.creator })),
    approvalRequests: approvalRequests.map(r => ({ id: r.id, ceremonyCode: r.ceremonyCode, status: r.status }))
  });

  // Filtrar cerimônias criadas pelo usuário conectado
  const userCeremonies = ceremonies.filter(c => {
    const isCreator = c.creator?.toLowerCase() === connectedAddress?.toLowerCase();
    console.log('Checking ceremony:', { 
      ceremonyId: c.id, 
      ceremonyCreator: c.creator, 
      connectedAddress, 
      isCreator 
    });
    return isCreator;
  });
  
  console.log('User ceremonies found:', userCeremonies.length);
  
  // TEMPORÁRIO: Se não encontrar cerimônias do usuário, mostrar todas para debug
  const ceremoniesToShow = userCeremonies.length > 0 ? userCeremonies : ceremonies;
  console.log('Ceremonies to show:', ceremoniesToShow.length, userCeremonies.length === 0 ? '(showing all for debug)' : '(user ceremonies only)');
  
  const userCeremonyCodes = new Set(ceremoniesToShow.map(c => c.id));
  
  // Filtrar solicitações apenas para cerimônias do usuário
  const userApprovalRequests = approvalRequests.filter(request => 
    userCeremonyCodes.has(request.ceremonyCode)
  );
  
  // Filtrar solicitações por status e cerimônia selecionada
  const filteredRequests = userApprovalRequests.filter(request => {
    const matchesStatus = filter === 'all' || request.status === filter;
    const matchesCeremony = selectedCeremony === 'all' || request.ceremonyCode === selectedCeremony;
    
    console.log('Filtering request:', {
      requestId: request.id,
      ceremonyCode: request.ceremonyCode,
      isUserCeremony: userCeremonyCodes.has(request.ceremonyCode),
      matchesStatus,
      matchesCeremony,
      willShow: matchesStatus && matchesCeremony
    });
    
    return matchesStatus && matchesCeremony;
  });

  // Calcular estatísticas apenas para cerimônias do usuário
  const pendingCount = userApprovalRequests.filter(r => r.status === 'pending').length;
  const totalRequests = userApprovalRequests.length;

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

  return (
    <div className="space-y-6">
      {/* Header with Stats */}
      <div className="stats shadow w-full">
        <div className="stat">
          <div className="stat-figure text-primary">
            <UserGroupIcon className="w-8 h-8" />
          </div>
          <div className="stat-title">Suas Cerimônias</div>
          <div className="stat-value text-primary">{ceremoniesToShow.length}</div>
          <div className="stat-desc">Com solicitações pendentes</div>
        </div>
        <div className="stat">
          <div className="stat-figure text-warning">
            <ClockIcon className="w-8 h-8" />
          </div>
          <div className="stat-title">Aprovações Pendentes</div>
          <div className="stat-value text-warning">{pendingCount}</div>
          <div className="stat-desc">Aguardando sua aprovação</div>
        </div>
        <div className="stat">
          <div className="stat-figure text-success">
            <CheckIcon className="w-8 h-8" />
          </div>
          <div className="stat-title">Total de Solicitações</div>
          <div className="stat-value text-success">{totalRequests}</div>
          <div className="stat-desc">Suas cerimônias</div>
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
                <option value="all">Suas Cerimônias</option>
                {ceremoniesToShow.map(ceremony => (
                  <option key={ceremony.id} value={ceremony.id}>
                    {ceremony.name}
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
      {ceremoniesToShow.length === 0 ? (
        <div className="card bg-base-100 shadow-xl">
          <div className="card-body text-center">
            <UserGroupIcon className="w-16 h-16 mx-auto text-gray-400 mb-4" />
            <h3 className="text-xl font-semibold mb-2">Modo Debug Ativo</h3>
            <p className="text-gray-600">
              {userCeremonies.length === 0 
                ? "Nenhuma cerimônia encontrada com filtro de ownership. Mostrando todas para debug."
                : "Você ainda não criou nenhuma cerimônia. Apenas criadores de cerimônias podem aprovar solicitações de entrada."
              }
            </p>
          </div>
        </div>
      ) : filteredRequests.length === 0 ? (
        <div className="card bg-base-100 shadow-xl">
          <div className="card-body text-center">
            <ExclamationTriangleIcon className="w-16 h-16 mx-auto text-gray-400 mb-4" />
            <h3 className="text-lg font-semibold">Nenhuma solicitação encontrada</h3>
            <p className="text-gray-600">
              {filter === 'pending' 
                ? "Não há solicitações pendentes para suas cerimônias."
                : "Nenhuma solicitação corresponde aos filtros selecionados."
              }
            </p>
          </div>
        </div>
      ) : (
        <div className="space-y-4">
          {filteredRequests.map(request => {
            return (
              <div key={request.id} className="card bg-base-100 shadow-xl">
                <div className="card-body">
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <h3 className="card-title">
                        Ceremony: {request.ceremonyCode}
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
                          onClick={() => handleApprove(request)}
                          disabled={!connectedAddress || !userCeremonyCodes.has(request.ceremonyCode)}
                          title={!userCeremonyCodes.has(request.ceremonyCode) ? "Apenas o criador da cerimônia pode aprovar" : ""}
                        >
                          <CheckIcon className="w-4 h-4" />
                          Aprovar
                        </button>
                        <button 
                          className="btn btn-error btn-sm"
                          onClick={() => handleReject(request)}
                          disabled={!connectedAddress || !userCeremonyCodes.has(request.ceremonyCode)}
                          title={!userCeremonyCodes.has(request.ceremonyCode) ? "Apenas o criador da cerimônia pode rejeitar" : ""}
                        >
                          <XMarkIcon className="w-4 h-4" />
                          Rejeitar
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