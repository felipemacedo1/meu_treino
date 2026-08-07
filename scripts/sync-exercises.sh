#!/usr/bin/env bash
# Dispara a sincronização do catálogo de exercícios com o wger.
# O catálogo já vem completo no banco (migration V3); isso serve para atualizar.
set -e
cd "$(dirname "$0")/.."

API="${API_URL:-http://localhost:${API_PORT:-8080}}"
EMAIL="${1:-}"
PASSWORD="${2:-}"

if [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
  echo "Uso: bash scripts/sync-exercises.sh <email> <senha>"
  echo "     (precisa de uma conta porque o endpoint é autenticado)"
  exit 1
fi

TOKEN=$(curl -fsS -X POST "$API/api/auth/login" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')

echo "==> Iniciando sync"
curl -fsS -X POST "$API/api/sync/wger" -H "Authorization: Bearer $TOKEN"; echo

echo "==> Acompanhando (Ctrl+C para sair)"
while true; do
  STATUS=$(curl -fsS "$API/api/sync/status" -H "Authorization: Bearer $TOKEN")
  echo "$STATUS"
  echo "$STATUS" | grep -q '"running":false' && break
  sleep 5
done
