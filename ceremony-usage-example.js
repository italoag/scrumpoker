// Exemplo prático de uso do ScrumPoker - Inicialização de Cerimônias
// Este script demonstra o fluxo completo de criação e uso de cerimônias

import { ethers } from 'ethers';

// Configuração do contrato (substitua pelos valores reais do seu deployment)
const SCRUMPOKER_ADDRESS = "0x..."; // Endereço do contrato Diamond deployado
const SCRUMPOKER_ABI = [
    // CeremonyFacet functions
    "function startCeremony(uint256 _sprintNumber) external returns (string memory)",
    "function ceremonyExists(string memory _code) external view returns (bool)",
    "function getCeremony(string memory _code) external view returns (string memory code, uint256 sprintNumber, uint256 startTime, uint256 endTime, address scrumMaster, bool active, address[] memory participants)",
    "function requestCeremonyEntry(string memory _code) external",
    "function approveEntry(string memory _code, address _participant) external",
    "function isApproved(string memory _code, address _participant) external view returns (bool)",
    "function hasRequestedEntry(string memory _code, address _participant) external view returns (bool)",
    "function concludeCeremony(string memory _code) external",
    
    // Events
    "event CeremonyStarted(string ceremonyCode, uint256 sprintNumber, uint256 startTime, address indexed scrumMaster)",
    "event CeremonyEntryRequested(string ceremonyCode, address indexed participant)",
    "event EntryApproved(string ceremonyCode, address indexed participant)",
    "event CeremonyConcluded(string ceremonyCode, uint256 endTime, uint256 sprintNumber)"
];

class ScrumPokerManager {
    constructor(provider, contractAddress) {
        this.provider = provider;
        this.contract = new ethers.Contract(contractAddress, SCRUMPOKER_ABI, provider);
    }

    // Conecta com uma carteira específica
    connect(signer) {
        return new ScrumPokerManager(signer, this.contract.address);
    }

    /**
     * Inicia uma nova cerimônia
     * @param {number} sprintNumber - Número do sprint
     * @returns {Promise<{ceremonyCode: string, transaction: object}>}
     */
    async startCeremony(sprintNumber) {
        console.log(`🚀 Iniciando cerimônia para Sprint ${sprintNumber}...`);
        
        try {
            // Executa a transação
            const tx = await this.contract.startCeremony(sprintNumber);
            console.log(`📝 Transação enviada: ${tx.hash}`);
            
            // Aguarda confirmação
            const receipt = await tx.wait();
            console.log(`✅ Transação confirmada no bloco: ${receipt.blockNumber}`);
            
            // Busca o evento CeremonyStarted para obter o código
            const ceremonyStartedEvent = receipt.events?.find(
                event => event.event === 'CeremonyStarted'
            );
            
            if (ceremonyStartedEvent) {
                const ceremonyCode = ceremonyStartedEvent.args.ceremonyCode;
                console.log(`🎯 Cerimônia criada com código: ${ceremonyCode}`);
                
                return {
                    ceremonyCode,
                    transaction: receipt,
                    sprintNumber: ceremonyStartedEvent.args.sprintNumber.toNumber(),
                    startTime: new Date(ceremonyStartedEvent.args.startTime.toNumber() * 1000),
                    scrumMaster: ceremonyStartedEvent.args.scrumMaster
                };
            } else {
                // Fallback: busca o código através de call estático
                const ceremonyCode = await this.contract.callStatic.startCeremony(sprintNumber);
                console.log(`🎯 Cerimônia criada com código: ${ceremonyCode}`);
                
                return { ceremonyCode, transaction: receipt };
            }
        } catch (error) {
            console.error(`❌ Erro ao iniciar cerimônia:`, error.message);
            throw error;
        }
    }

    /**
     * Verifica se uma cerimônia existe
     * @param {string} ceremonyCode - Código da cerimônia
     * @returns {Promise<boolean>}
     */
    async ceremonyExists(ceremonyCode) {
        try {
            const exists = await this.contract.ceremonyExists(ceremonyCode);
            console.log(`🔍 Cerimônia ${ceremonyCode} ${exists ? 'existe' : 'não existe'}`);
            return exists;
        } catch (error) {
            console.error(`❌ Erro ao verificar cerimônia:`, error.message);
            return false;
        }
    }

    /**
     * Obtém detalhes completos de uma cerimônia
     * @param {string} ceremonyCode - Código da cerimônia
     * @returns {Promise<object>}
     */
    async getCeremonyDetails(ceremonyCode) {
        try {
            console.log(`📋 Buscando detalhes da cerimônia ${ceremonyCode}...`);
            
            const ceremony = await this.contract.getCeremony(ceremonyCode);
            
            const details = {
                code: ceremony.code,
                sprintNumber: ceremony.sprintNumber.toNumber(),
                startTime: new Date(ceremony.startTime.toNumber() * 1000),
                endTime: ceremony.endTime.toNumber() > 0 ? 
                    new Date(ceremony.endTime.toNumber() * 1000) : null,
                scrumMaster: ceremony.scrumMaster,
                active: ceremony.active,
                participants: ceremony.participants,
                participantCount: ceremony.participants.length
            };
            
            console.log(`📊 Detalhes da cerimônia:`, {
                ...details,
                startTime: details.startTime.toISOString(),
                endTime: details.endTime?.toISOString() || 'Em andamento'
            });
            
            return details;
        } catch (error) {
            console.error(`❌ Erro ao buscar detalhes:`, error.message);
            throw error;
        }
    }

    /**
     * Solicita entrada em uma cerimônia
     * @param {string} ceremonyCode - Código da cerimônia
     * @returns {Promise<object>}
     */
    async requestEntry(ceremonyCode) {
        try {
            console.log(`🙋 Solicitando entrada na cerimônia ${ceremonyCode}...`);
            
            const tx = await this.contract.requestCeremonyEntry(ceremonyCode);
            const receipt = await tx.wait();
            
            console.log(`✅ Solicitação de entrada enviada com sucesso`);
            return receipt;
        } catch (error) {
            console.error(`❌ Erro ao solicitar entrada:`, error.message);
            throw error;
        }
    }

    /**
     * Aprova entrada de um participante (apenas Scrum Master)
     * @param {string} ceremonyCode - Código da cerimônia
     * @param {string} participantAddress - Endereço do participante
     * @returns {Promise<object>}
     */
    async approveEntry(ceremonyCode, participantAddress) {
        try {
            console.log(`👍 Aprovando entrada de ${participantAddress} na cerimônia ${ceremonyCode}...`);
            
            const tx = await this.contract.approveEntry(ceremonyCode, participantAddress);
            const receipt = await tx.wait();
            
            console.log(`✅ Entrada aprovada com sucesso`);
            return receipt;
        } catch (error) {
            console.error(`❌ Erro ao aprovar entrada:`, error.message);
            throw error;
        }
    }

    /**
     * Verifica se um participante foi aprovado
     * @param {string} ceremonyCode - Código da cerimônia
     * @param {string} participantAddress - Endereço do participante
     * @returns {Promise<boolean>}
     */
    async isParticipantApproved(ceremonyCode, participantAddress) {
        try {
            const isApproved = await this.contract.isApproved(ceremonyCode, participantAddress);
            console.log(`🔍 Participante ${participantAddress} ${isApproved ? 'está aprovado' : 'não está aprovado'}`);
            return isApproved;
        } catch (error) {
            console.error(`❌ Erro ao verificar aprovação:`, error.message);
            return false;
        }
    }

    /**
     * Conclui uma cerimônia (apenas Scrum Master)
     * @param {string} ceremonyCode - Código da cerimônia
     * @returns {Promise<object>}
     */
    async concludeCeremony(ceremonyCode) {
        try {
            console.log(`🏁 Concluindo cerimônia ${ceremonyCode}...`);
            
            const tx = await this.contract.concludeCeremony(ceremonyCode);
            const receipt = await tx.wait();
            
            console.log(`✅ Cerimônia concluída com sucesso`);
            return receipt;
        } catch (error) {
            console.error(`❌ Erro ao concluir cerimônia:`, error.message);
            throw error;
        }
    }

    /**
     * Monitora eventos de uma cerimônia
     * @param {string} ceremonyCode - Código da cerimônia
     * @param {function} callback - Função callback para eventos
     */
    async monitorCeremonyEvents(ceremonyCode, callback) {
        console.log(`👁️ Monitorando eventos da cerimônia ${ceremonyCode}...`);
        
        // Filtros para eventos relacionados à cerimônia
        const filters = {
            ceremonyStarted: this.contract.filters.CeremonyStarted(ceremonyCode),
            entryRequested: this.contract.filters.CeremonyEntryRequested(ceremonyCode),
            entryApproved: this.contract.filters.EntryApproved(ceremonyCode),
            ceremonyConcluded: this.contract.filters.CeremonyConcluded(ceremonyCode)
        };

        // Configura listeners
        Object.entries(filters).forEach(([eventName, filter]) => {
            this.contract.on(filter, (...args) => {
                const event = args[args.length - 1]; // Último argumento é sempre o evento
                callback({
                    type: eventName,
                    ceremonyCode,
                    event,
                    args: args.slice(0, -1)
                });
            });
        });
    }
}

// Exemplo de uso completo
async function exemploCompleto() {
    // Configuração do provider (substitua pela sua configuração)
    const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
    
    // Carteiras de exemplo
    const scrumMaster = new ethers.Wallet("0x...", provider); // Private key do Scrum Master
    const participant1 = new ethers.Wallet("0x...", provider); // Private key do Participante 1
    const participant2 = new ethers.Wallet("0x...", provider); // Private key do Participante 2
    
    // Instancia o manager
    const scrumPoker = new ScrumPokerManager(provider, SCRUMPOKER_ADDRESS);
    
    try {
        console.log("=== EXEMPLO COMPLETO DE USO DO SCRUMPOKER ===\n");
        
        // 1. Scrum Master inicia uma cerimônia
        console.log("1️⃣ INICIANDO CERIMÔNIA");
        const scrumMasterManager = scrumPoker.connect(scrumMaster);
        const { ceremonyCode } = await scrumMasterManager.startCeremony(1);
        
        // 2. Verifica se a cerimônia foi criada
        console.log("\n2️⃣ VERIFICANDO CERIMÔNIA");
        await scrumPoker.ceremonyExists(ceremonyCode);
        
        // 3. Obtém detalhes da cerimônia
        console.log("\n3️⃣ DETALHES DA CERIMÔNIA");
        await scrumPoker.getCeremonyDetails(ceremonyCode);
        
        // 4. Participantes solicitam entrada
        console.log("\n4️⃣ SOLICITAÇÕES DE ENTRADA");
        const participant1Manager = scrumPoker.connect(participant1);
        const participant2Manager = scrumPoker.connect(participant2);
        
        await participant1Manager.requestEntry(ceremonyCode);
        await participant2Manager.requestEntry(ceremonyCode);
        
        // 5. Scrum Master aprova entradas
        console.log("\n5️⃣ APROVAÇÕES DE ENTRADA");
        await scrumMasterManager.approveEntry(ceremonyCode, participant1.address);
        await scrumMasterManager.approveEntry(ceremonyCode, participant2.address);
        
        // 6. Verifica aprovações
        console.log("\n6️⃣ VERIFICANDO APROVAÇÕES");
        await scrumPoker.isParticipantApproved(ceremonyCode, participant1.address);
        await scrumPoker.isParticipantApproved(ceremonyCode, participant2.address);
        
        // 7. Monitora eventos (opcional)
        console.log("\n7️⃣ MONITORANDO EVENTOS");
        scrumPoker.monitorCeremonyEvents(ceremonyCode, (eventData) => {
            console.log(`📡 Evento recebido:`, eventData);
        });
        
        // 8. Obtém detalhes finais
        console.log("\n8️⃣ DETALHES FINAIS");
        const finalDetails = await scrumPoker.getCeremonyDetails(ceremonyCode);
        
        console.log("\n✅ EXEMPLO CONCLUÍDO COM SUCESSO!");
        console.log(`🎯 Código da cerimônia: ${ceremonyCode}`);
        console.log(`👥 Participantes aprovados: ${finalDetails.participantCount}`);
        
    } catch (error) {
        console.error("\n❌ ERRO NO EXEMPLO:", error.message);
    }
}

// Exemplo simplificado para testes rápidos
async function exemploSimples() {
    const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
    const signer = new ethers.Wallet("0x...", provider);
    const scrumPoker = new ScrumPokerManager(provider, SCRUMPOKER_ADDRESS).connect(signer);
    
    // Inicia cerimônia e obtém código
    const { ceremonyCode } = await scrumPoker.startCeremony(1);
    
    // Verifica se existe
    const exists = await scrumPoker.ceremonyExists(ceremonyCode);
    
    // Obtém detalhes
    const details = await scrumPoker.getCeremonyDetails(ceremonyCode);
    
    console.log("Cerimônia criada:", { ceremonyCode, exists, details });
}

// Exporta as classes e funções
export { ScrumPokerManager, exemploCompleto, exemploSimples };

// Para uso em Node.js, descomente a linha abaixo:
// exemploCompleto().catch(console.error);