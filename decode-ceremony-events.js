// Script para decodificar eventos do ScrumPoker e extrair códigos de cerimônia
import { ethers } from 'ethers';

// ABI dos eventos do ScrumPoker
const EVENTS_ABI = [
    "event CeremonyStarted(string ceremonyCode, uint256 sprintNumber, uint256 startTime, address indexed scrumMaster)",
    "event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)"
];

// Função para decodificar logs de transação
function decodeScrumPokerLogs(transactionReceipt) {
    const iface = new ethers.utils.Interface(EVENTS_ABI);
    const decodedEvents = [];
    
    console.log("🔍 Analisando logs da transação...\n");
    
    transactionReceipt.logs.forEach((log, index) => {
        try {
            const decoded = iface.parseLog(log);
            decodedEvents.push({
                logIndex: index,
                eventName: decoded.name,
                args: decoded.args,
                topics: log.topics,
                data: log.data
            });
            
            console.log(`📋 Log ${index}: ${decoded.name}`);
            
            if (decoded.name === 'CeremonyStarted') {
                console.log(`🎯 CÓDIGO DA CERIMÔNIA ENCONTRADO: "${decoded.args.ceremonyCode}"`);
                console.log(`📊 Sprint Number: ${decoded.args.sprintNumber}`);
                console.log(`⏰ Start Time: ${new Date(decoded.args.startTime * 1000).toISOString()}`);
                console.log(`👤 Scrum Master: ${decoded.args.scrumMaster}`);
            } else if (decoded.name === 'RoleGranted') {
                console.log(`🔐 Role: ${decoded.args.role}`);
                console.log(`👤 Account: ${decoded.args.account}`);
                console.log(`📤 Sender: ${decoded.args.sender}`);
            }
            
            console.log("---");
            
        } catch (error) {
            console.log(`⚠️  Log ${index}: Não foi possível decodificar (pode ser de outro contrato)`);
        }
    });
    
    return decodedEvents;
}

// Função específica para extrair código de cerimônia
function extractCeremonyCode(transactionReceipt) {
    const iface = new ethers.utils.Interface(EVENTS_ABI);
    
    for (const log of transactionReceipt.logs) {
        try {
            const decoded = iface.parseLog(log);
            if (decoded.name === 'CeremonyStarted') {
                return {
                    ceremonyCode: decoded.args.ceremonyCode,
                    sprintNumber: decoded.args.sprintNumber.toNumber(),
                    startTime: new Date(decoded.args.startTime * 1000),
                    scrumMaster: decoded.args.scrumMaster
                };
            }
        } catch (error) {
            // Ignora logs que não conseguimos decodificar
            continue;
        }
    }
    
    return null;
}

// Exemplo de uso com seus dados
const yourTransactionReceipt = {
  "type": "eip1559",
  "status": "success",
  "cumulativeGasUsed": "241873",
  "logs": [
    {
      "address": "0xb19b36b1456e65e3a6d514d3f715f204bd59f431",
      "topics": [
        "0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d",
        "0x1c2f558011c76cbc7ca8555104ce1117bf3d35304ac3c5deed844dd87a088fce",
        "0x000000000000000000000000f58db91e1a58ce2ec2bfb92aeb1ff2aa3310e8ba",
        "0x000000000000000000000000f58db91e1a58ce2ec2bfb92aeb1ff2aa3310e8ba"
      ],
      "data": "0x",
      "blockHash": "0x7fc89381c4b3bbc101b6382e632b247bfbc6c8bd0d59a1e92331eee840055eca",
      "blockNumber": "8",
      "blockTimestamp": "0x687520f2",
      "transactionHash": "0xbcaf3238fb69f3b80c559c092ee0994b48b8da4998b9307275f0a481174cf0e2",
      "transactionIndex": 0,
      "logIndex": 0,
      "removed": false
    },
    {
      "address": "0xb19b36b1456e65e3a6d514d3f715f204bd59f431",
      "topics": [
        "0x6747cd38b371babbeb3750af08ddb691b4f5d76dd074cbcd9ed09415f507781f",
        "0x000000000000000000000000f58db91e1a58ce2ec2bfb92aeb1ff2aa3310e8ba"
      ],
      "data": "0x0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000687520f20000000000000000000000000000000000000000000000000000000000000009434552454d4f4e59300000000000000000000000000000000000000000000000",
      "blockHash": "0x7fc89381c4b3bbc101b6382e632b247bfbc6c8bd0d59a1e92331eee840055eca",
      "blockNumber": "8",
      "blockTimestamp": "0x687520f2",
      "transactionHash": "0xbcaf3238fb69f3b80c559c092ee0994b48b8da4998b9307275f0a481174cf0e2",
      "transactionIndex": 0,
      "logIndex": 1,
      "removed": false
    }
  ],
  "logsBloom": "0x00000104000000000000000000000000000000400000000020000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000400000000000000000000000000000000080000000000000000000000000000000000000000000080001000000000000000000000000000000000000000000020000000000000000100040000000000000000000000000040000000000000000000000000000000000000000000000000",
  "transactionHash": "0xbcaf3238fb69f3b80c559c092ee0994b48b8da4998b9307275f0a481174cf0e2",
  "transactionIndex": 0,
  "blockHash": "0x7fc89381c4b3bbc101b6382e632b247bfbc6c8bd0d59a1e92331eee840055eca",
  "blockNumber": "8",
  "gasUsed": "241873",
  "effectiveGasPrice": "1458109183",
  "blobGasPrice": "1",
  "from": "0xf58db91e1a58ce2ec2bfb92aeb1ff2aa3310e8ba",
  "to": "0xb19b36b1456e65e3a6d514d3f715f204bd59f431",
  "contractAddress": null,
  "chainId": 31337
};

console.log("🎯 DECODIFICANDO TRANSAÇÃO DO SCRUMPOKER\n");
console.log("=".repeat(50));

// Decodifica todos os eventos
const decodedEvents = decodeScrumPokerLogs(yourTransactionReceipt);

// Extrai especificamente o código da cerimônia
const ceremonyInfo = extractCeremonyCode(yourTransactionReceipt);

if (ceremonyInfo) {
    console.log("\n✅ INFORMAÇÕES DA CERIMÔNIA EXTRAÍDAS:");
    console.log("=".repeat(50));
    console.log(`🎯 Código da Cerimônia: "${ceremonyInfo.ceremonyCode}"`);
    console.log(`📊 Número do Sprint: ${ceremonyInfo.sprintNumber}`);
    console.log(`⏰ Data/Hora de Início: ${ceremonyInfo.startTime.toISOString()}`);
    console.log(`👤 Scrum Master: ${ceremonyInfo.scrumMaster}`);
    
    console.log("\n📋 PRÓXIMOS PASSOS:");
    console.log("=".repeat(50));
    console.log(`1. Use o código "${ceremonyInfo.ceremonyCode}" nos métodos subsequentes`);
    console.log(`2. Exemplo: await contract.ceremonyExists("${ceremonyInfo.ceremonyCode}")`);
    console.log(`3. Exemplo: await contract.getCeremony("${ceremonyInfo.ceremonyCode}")`);
    console.log(`4. Exemplo: await contract.requestCeremonyEntry("${ceremonyInfo.ceremonyCode}")`);
} else {
    console.log("\n❌ Não foi possível encontrar o evento CeremonyStarted");
}

// Função utilitária para uso em aplicações
function getCeremonyCodeFromReceipt(receipt) {
    const ceremonyInfo = extractCeremonyCode(receipt);
    return ceremonyInfo ? ceremonyInfo.ceremonyCode : null;
}

// Exporta as funções
export { 
    decodeScrumPokerLogs, 
    extractCeremonyCode, 
    getCeremonyCodeFromReceipt 
};

// Para teste direto no Node.js, descomente:
// console.log("\n🔍 ANÁLISE MANUAL DOS DADOS:");
// console.log("Topic 1 (CeremonyStarted signature):", yourTransactionReceipt.logs[1].topics[0]);
// console.log("Data hex:", yourTransactionReceipt.logs[1].data);

// Decodificação manual do data field do segundo log
const dataHex = "0x0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000687520f20000000000000000000000000000000000000000000000000000000000000009434552454d4f4e59300000000000000000000000000000000000000000000000";

// Remove o 0x prefix
const cleanHex = dataHex.slice(2);

// Os primeiros 64 caracteres (32 bytes) indicam o offset da string
const stringOffset = parseInt(cleanHex.slice(0, 64), 16);
console.log("\n🔍 DECODIFICAÇÃO MANUAL:");
console.log(`String offset: ${stringOffset} (posição ${stringOffset} em bytes)`);

// Os próximos 64 caracteres (32 bytes) são o sprintNumber
const sprintNumber = parseInt(cleanHex.slice(64, 128), 16);
console.log(`Sprint number: ${sprintNumber}`);

// Os próximos 64 caracteres (32 bytes) são o timestamp
const timestamp = parseInt(cleanHex.slice(128, 192), 16);
console.log(`Timestamp: ${timestamp} (${new Date(timestamp * 1000).toISOString()})`);

// A partir do offset (posição 96 = 0x60), temos o comprimento da string
const stringLengthHex = cleanHex.slice(192, 256); // Próximos 32 bytes
const stringLength = parseInt(stringLengthHex, 16);
console.log(`String length: ${stringLength} caracteres`);

// Depois do comprimento, temos os dados da string
const stringDataHex = cleanHex.slice(256, 256 + (stringLength * 2));
const ceremonyCode = ethers.utils.toUtf8String("0x" + stringDataHex);
console.log(`🎯 CÓDIGO EXTRAÍDO MANUALMENTE: "${ceremonyCode}"`);