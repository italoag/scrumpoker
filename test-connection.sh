#!/bin/bash

# Script para testar a conexão entre Next.js e Ponder
echo "🔍 Testando conexão Next.js <-> Ponder..."

# Verificar se o Ponder está rodando
echo "📡 Verificando se Ponder está ativo..."
PONDER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:42069/health)

if [ "$PONDER_STATUS" != "200" ]; then
    echo "❌ Ponder não está rodando em localhost:42069 (HTTP $PONDER_STATUS)"
    echo "   Por favor, inicie o Ponder primeiro"
    exit 1
fi

echo "✅ Ponder está ativo"

# Testar a query GraphQL diretamente
echo "🔍 Testando query GraphQL..."
GRAPHQL_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"query": "{ ceremonys(orderBy: \"createdAt\", orderDirection: \"desc\") { items { id title status } } }"}' \
  http://localhost:42069)

echo "📊 Resposta GraphQL:"
echo "$GRAPHQL_RESPONSE" | jq '.' 2>/dev/null || echo "$GRAPHQL_RESPONSE"

# Verificar se há dados
CEREMONY_COUNT=$(echo "$GRAPHQL_RESPONSE" | jq '.data.ceremonys.items | length' 2>/dev/null || echo "0")
echo "📈 Número de cerimônias encontradas: $CEREMONY_COUNT"

# Iniciar Next.js em background e testar
echo "🚀 Iniciando Next.js em background..."
cd packages/nextjs
npm run dev > /tmp/nextjs.log 2>&1 &
NEXTJS_PID=$!

echo "⏳ Aguardando Next.js inicializar..."
sleep 10

# Verificar se Next.js está rodando
NEXTJS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)

if [ "$NEXTJS_STATUS" == "200" ]; then
    echo "✅ Next.js está rodando"
    
    # Testar a página do dashboard
    echo "🔍 Testando página do dashboard..."
    DASHBOARD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ponder-greetings)
    
    if [ "$DASHBOARD_STATUS" == "200" ]; then
        echo "✅ Dashboard acessível"
        echo "🌐 Acesse: http://localhost:3000/ponder-greetings"
        echo "📝 Logs do Next.js em: /tmp/nextjs.log"
        echo "🔧 Para parar o Next.js: kill $NEXTJS_PID"
        echo ""
        echo "🎯 Next.js PID: $NEXTJS_PID"
        echo "💡 Verifique o console do navegador para logs de debug"
    else
        echo "❌ Dashboard não acessível (HTTP $DASHBOARD_STATUS)"
        kill $NEXTJS_PID
        exit 1
    fi
else
    echo "❌ Next.js não iniciou corretamente"
    kill $NEXTJS_PID
    exit 1
fi