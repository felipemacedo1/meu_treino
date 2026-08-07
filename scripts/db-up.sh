#!/usr/bin/env bash
# Sobe apenas o Postgres (util para rodar backend/app localmente).
set -e
cd "$(dirname "$0")/.."
source scripts/_compose.sh

$COMPOSE up -d db
echo "Postgres subindo em localhost:${DB_PORT:-5433}"
