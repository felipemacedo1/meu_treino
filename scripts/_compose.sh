#!/usr/bin/env bash
# Detecta se o docker compose disponivel e o plugin v2 ou o binario v1.
set -e

if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
  cat >&2 <<'WARN'
[aviso] Você está usando o docker-compose v1. Com Docker >= 25 ele falha ao
        recriar containers ("KeyError: 'ContainerConfig'").
        Instale o plugin v2 (não precisa de sudo):

            bash scripts/install-compose-v2.sh

WARN
else
  echo "docker compose nao encontrado. Instale o Docker Compose para continuar." >&2
  exit 1
fi

export COMPOSE
