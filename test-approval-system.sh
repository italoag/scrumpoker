#!/bin/bash

echo "🚀 Testando sistema de aprovação de cerimônias"

# Verificar se o Ponder está rodando
echo "📡 Verificando Ponder..."
curl -s http://localhost:42069/graphql > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Ponder está rodando"
else
    echo "❌ Ponder não está rodando. Inicie com: cd packages/ponder && npm run dev"
    exit 1
fi

# Verificar se a blockchain local está rodando
echo "⛓️  Verificando blockchain local..."
curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545 > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Blockchain local está rodando"
else
    echo "❌ Blockchain local não está rodando. Inicie com: cd packages/foundry && anvil"
    exit 1
fi

# Verificar se o frontend está rodando
echo "🌐 Verificando frontend..."
curl -s http://localhost:3000 > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Frontend está rodando"
else
    echo "❌ Frontend não está rodando. Inicie com: cd packages/nextjs && npm run dev"
    exit 1
fi

echo ""
echo "🎯 Todos os serviços estão rodando!"
echo "📋 Para testar o sistema de aprovação:"
echo "1. Acesse http://localhost:3000"
echo "2. Conecte sua carteira"
echo "3. Crie uma cerimônia na aba 'Create'"
echo "4. Use outra conta para solicitar participação na aba 'Participants'"
echo "5. Volte para a conta criadora e aprove na aba 'Approvals'"
echo ""
echo "🔍 Para debug, verifique os logs do Ponder e do console do browser"