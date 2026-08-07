#!/usr/bin/env bash
# CUIDADO: apaga o banco (usuários, treinos, histórico) e recria do zero.
set -e
cd "$(dirname "$0")/.."
source scripts/_compose.sh

read -r -p "Isso apaga TODOS os dados locais. Continuar? (digite 'sim'): " answer
if [ "$answer" != "sim" ]; then
  echo "Cancelado."
  exit 0
fi

$COMPOSE down -v
$COMPOSE up -d db
echo "Banco recriado. Suba a API com: bash scripts/start.sh"
