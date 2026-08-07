#!/usr/bin/env bash
# Roda o backend localmente (usa o Postgres do docker-compose em localhost:5433).
set -e
cd "$(dirname "$0")/../backend"

export DB_URL="${DB_URL:-jdbc:postgresql://localhost:${DB_PORT:-5433}/${POSTGRES_DB:-meu_treino}}"
export DB_USER="${POSTGRES_USER:-meutreino}"
export DB_PASSWORD="${POSTGRES_PASSWORD:-meutreino}"

mvn -B spring-boot:run
