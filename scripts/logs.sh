#!/usr/bin/env bash
# Mostra os logs (padrão: api). Ex.: bash scripts/logs.sh web
set -e
cd "$(dirname "$0")/.."
source scripts/_compose.sh

$COMPOSE logs -f --tail=200 "${1:-api}"
