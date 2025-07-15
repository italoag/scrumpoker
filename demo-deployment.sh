#!/bin/bash

# 🚀 Exemplo de Uso do Sistema de Deployment Automatizado
# Este script demonstra diferentes cenários de uso

echo "🎯 Demonstração do Sistema de Deployment Automatizado"
echo "===================================================="

# Função para pausar e aguardar confirmação
pause() {
    echo ""
    read -p "Pressione Enter para continuar..."
    echo ""
}

# Função para executar comando com logging
run_command() {
    local description="$1"
    local command="$2"
    
    echo "🔄 $description"
    echo "Comando: $command"
    pause
    
    eval "$command"
    
    if [ $? -eq 0 ]; then
        echo "✅ $description - Concluído com sucesso!"
    else
        echo "❌ $description - Falhou!"
        exit 1
    fi
    echo ""
}

echo "Este script demonstra como usar o sistema de deployment automatizado."
echo "Certifique-se de que:"
echo "  ✅ Anvil está rodando (yarn chain)"
echo "  ✅ Você está no diretório correto"
echo ""

# Cenário 1: Deployment Completo
echo "📋 CENÁRIO 1: Deployment Completo Automatizado"
echo "Este é o caso de uso mais comum - deployment completo com todas as configurações."
run_command "Deployment completo automatizado" "yarn deploy:auto"

# Cenário 2: Apenas atualizar Ponder
echo "📋 CENÁRIO 2: Atualização Apenas do Ponder"
echo "Útil quando você já tem contratos deployados e quer apenas atualizar o Ponder."
run_command "Atualização da configuração do Ponder" "yarn foundry:update:ponder"

# Cenário 3: Deployment com verbose
echo "📋 CENÁRIO 3: Deployment com Output Detalhado"
echo "Para debugging ou quando você quer ver todos os detalhes."
run_command "Deployment com output detalhado" "yarn deploy:full"

# Cenário 4: Deployment rápido
echo "📋 CENÁRIO 4: Deployment Rápido (sem inicializações)"
echo "Para testes rápidos onde você não precisa de inicializações."
run_command "Deployment rápido sem inicializações" "yarn deploy:quick"

# Cenário 5: Apenas gerar ABIs
echo "📋 CENÁRIO 5: Geração de ABIs"
echo "Para quando você modificou contratos e quer apenas regenerar ABIs."
run_command "Geração de ABIs" "yarn foundry:generate:abis"

# Cenário 6: Apenas inicializar contratos
echo "📋 CENÁRIO 6: Inicialização de Contratos"
echo "Para quando você quer apenas executar inicializações."
run_command "Inicialização de contratos" "yarn foundry:init:contracts"

echo "🎉 Demonstração Concluída!"
echo ""
echo "📊 Resumo dos Comandos Demonstrados:"
echo "  • yarn deploy:auto        - Deployment completo automatizado"
echo "  • yarn foundry:update:ponder - Atualiza apenas Ponder"
echo "  • yarn deploy:full        - Deployment com output detalhado"
echo "  • yarn deploy:quick       - Deployment rápido sem init"
echo "  • yarn foundry:generate:abis - Gera apenas ABIs"
echo "  • yarn foundry:init:contracts - Apenas inicializações"
echo ""
echo "💡 Para uso diário, recomendamos: yarn deploy:auto"
echo ""
echo "📖 Para mais informações, consulte: DEPLOYMENT-AUTOMATION.md"