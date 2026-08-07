#!/usr/bin/env bash
# Instala o plugin "docker compose" (v2) no diretório do usuário (~/.docker/cli-plugins).
#
# Por que: o binário antigo `docker-compose` (v1.29) quebra com Docker >= 25
# ao recriar containers ("KeyError: 'ContainerConfig'"). O plugin v2 resolve.
# Não precisa de sudo e é fácil de remover (apague o arquivo).
set -e

VERSION="${1:-v5.4.0}"
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64) ARCH="x86_64" ;;
  aarch64|arm64) ARCH="aarch64" ;;
  *) echo "Arquitetura não suportada: $ARCH" >&2; exit 1 ;;
esac

DEST="$HOME/.docker/cli-plugins"
mkdir -p "$DEST"
URL="https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-linux-${ARCH}"

echo "==> Baixando $URL"
curl -fSL "$URL" -o "$DEST/docker-compose"
chmod +x "$DEST/docker-compose"

echo "==> Instalado:"
docker compose version
