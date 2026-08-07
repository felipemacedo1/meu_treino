#!/usr/bin/env bash
# Para todos os containers (mantém os dados do banco).
set -e
cd "$(dirname "$0")/.."
source scripts/_compose.sh

$COMPOSE down
echo "Containers parados. Os dados do Postgres continuam no volume pgdata."
