import { execSync } from "child_process";
import { readFileSync, writeFileSync, existsSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * Script de deployment completo e automatizado
 * Este script executa todo o processo de deployment e configuração
 */

class AutomatedDeployment {
  constructor(options = {}) {
    this.network = options.network || "anvil";
    this.chainId = options.chainId || 31337;
    this.startBlock = options.startBlock || 4;
    this.verbose = options.verbose || false;
    this.skipPonder = options.skipPonder || false;
    this.skipInitialization = options.skipInitialization || false;
  }

  log(message, type = "info") {
    const timestamp = new Date().toISOString();
    const icons = {
      info: "ℹ️",
      success: "✅",
      warning: "⚠️",
      error: "❌",
      step: "🔄"
    };
    console.log(`${icons[type]} [${timestamp}] ${message}`);
  }

  async runCommand(command, description) {
    this.log(`${description}...`, "step");
    try {
      const result = execSync(command, { 
        cwd: join(__dirname, ".."),
        encoding: "utf8",
        stdio: this.verbose ? "inherit" : "pipe"
      });
      this.log(`${description} completed`, "success");
      return result;
    } catch (error) {
      this.log(`${description} failed: ${error.message}`, "error");
      throw error;
    }
  }

  async deployContracts() {
    this.log("Starting contract deployment", "step");
    
    // Compila os contratos
    await this.runCommand("forge build", "Compiling contracts");
    
    // Executa o deployment
    const deployCommand = `forge script script/DeployScrumPoker.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast`;
    await this.runCommand(deployCommand, "Deploying contracts");
    
    this.log("Contract deployment completed", "success");
  }

  async generateAbis() {
    this.log("Generating ABIs", "step");
    
    // Gera ABI combinado do Diamond
    await this.runCommand("node scripts-js/generateCombinedDiamondAbi.js", "Generating combined Diamond ABI");
    
    // Gera ABIs TypeScript
    await this.runCommand("node scripts-js/generateTsAbis.js", "Generating TypeScript ABIs");
    
    this.log("ABI generation completed", "success");
  }

  async updatePonderConfig() {
    if (this.skipPonder) {
      this.log("Skipping Ponder configuration update", "warning");
      return;
    }

    this.log("Updating Ponder configuration", "step");
    
    const updateCommand = `node scripts-js/updatePonderConfig.js ${this.network} ${this.chainId} ${this.startBlock}`;
    await this.runCommand(updateCommand, "Updating Ponder config");
    
    this.log("Ponder configuration updated", "success");
  }

  async initializeContracts() {
    if (this.skipInitialization) {
      this.log("Skipping contract initialization", "warning");
      return;
    }

    this.log("Initializing contracts", "step");
    
    // Verifica se existe script de inicialização
    const initScriptPath = join(__dirname, "..", "script", "InitializeContracts.s.sol");
    if (existsSync(initScriptPath)) {
      const initCommand = `forge script script/InitializeContracts.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast`;
      await this.runCommand(initCommand, "Running contract initialization");
    } else {
      this.log("No initialization script found, skipping", "warning");
    }
  }

  async restartPonder() {
    if (this.skipPonder) {
      this.log("Skipping Ponder restart", "warning");
      return;
    }

    this.log("Restarting Ponder for clean indexing", "step");
    
    try {
      // Para o Ponder se estiver rodando
      execSync("pkill -f ponder", { stdio: "ignore" });
      this.log("Stopped existing Ponder process", "success");
    } catch (error) {
      this.log("No existing Ponder process found", "info");
    }

    // Remove banco de dados antigo
    const ponderDbPath = join(__dirname, "..", "..", "ponder", ".ponder");
    if (existsSync(ponderDbPath)) {
      await this.runCommand(`rm -rf ${ponderDbPath}`, "Clearing Ponder database");
    }

    this.log("Ponder restart preparation completed", "success");
  }

  async generateDeploymentSummary() {
    this.log("Generating deployment summary", "step");
    
    const deploymentPath = join(__dirname, "..", "deployments", `${this.network}.json`);
    if (!existsSync(deploymentPath)) {
      this.log("Deployment file not found", "warning");
      return;
    }

    const deployment = JSON.parse(readFileSync(deploymentPath, "utf8"));
    
    const summary = {
      timestamp: new Date().toISOString(),
      network: this.network,
      chainId: this.chainId,
      startBlock: this.startBlock,
      addresses: deployment,
      status: "completed"
    };

    const summaryPath = join(__dirname, "..", "deployments", `${this.network}-summary.json`);
    writeFileSync(summaryPath, JSON.stringify(summary, null, 2));
    
    this.log("Deployment summary generated", "success");
    this.log(`📋 Summary saved to: ${summaryPath}`, "info");
    
    // Exibe resumo no console
    console.log("\n📊 DEPLOYMENT SUMMARY");
    console.log("=====================");
    console.log(`🌐 Network: ${this.network}`);
    console.log(`⛓️  Chain ID: ${this.chainId}`);
    console.log(`🎯 Start Block: ${this.startBlock}`);
    console.log(`💎 Diamond Address: ${deployment.ScrumPokerDiamond}`);
    console.log(`🏗️  Deployer: ${deployment.ScrumPokerDeployer}`);
    console.log("\n🔧 Facet Addresses:");
    console.log(`   AdminFacet: ${deployment.AdminFacet}`);
    console.log(`   NFTFacet: ${deployment.NFTFacet}`);
    console.log(`   CeremonyFacet: ${deployment.CeremonyFacet}`);
    console.log(`   VotingFacet: ${deployment.VotingFacet}`);
    console.log("\n✅ All systems ready for use!");
  }

  async run() {
    try {
      this.log("🚀 Starting automated deployment process", "step");
      
      // Executa todas as etapas
      await this.deployContracts();
      await this.generateAbis();
      await this.updatePonderConfig();
      await this.initializeContracts();
      await this.restartPonder();
      await this.generateDeploymentSummary();
      
      this.log("🎉 Automated deployment completed successfully!", "success");
      
    } catch (error) {
      this.log(`💥 Deployment failed: ${error.message}`, "error");
      process.exit(1);
    }
  }
}

// Função principal
function main() {
  const args = process.argv.slice(2);
  const options = {};
  
  // Parse argumentos
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    switch (arg) {
      case "--network":
        options.network = args[++i];
        break;
      case "--chain-id":
        options.chainId = parseInt(args[++i]);
        break;
      case "--start-block":
        options.startBlock = parseInt(args[++i]);
        break;
      case "--verbose":
        options.verbose = true;
        break;
      case "--skip-ponder":
        options.skipPonder = true;
        break;
      case "--skip-init":
        options.skipInitialization = true;
        break;
      case "--help":
        console.log(`
🚀 Automated Deployment Script

Usage: node scripts-js/automatedDeploy.js [options]

Options:
  --network <name>     Network name (default: anvil)
  --chain-id <id>      Chain ID (default: 31337)
  --start-block <num>  Start block for indexing (default: 4)
  --verbose            Show detailed output
  --skip-ponder        Skip Ponder configuration
  --skip-init          Skip contract initialization
  --help               Show this help message

Examples:
  node scripts-js/automatedDeploy.js
  node scripts-js/automatedDeploy.js --network localhost --start-block 1
  node scripts-js/automatedDeploy.js --verbose --skip-init
        `);
        process.exit(0);
        break;
    }
  }
  
  const deployment = new AutomatedDeployment(options);
  deployment.run();
}

// Executa apenas se chamado diretamente
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { AutomatedDeployment };