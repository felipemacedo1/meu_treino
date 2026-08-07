#!/usr/bin/env bash
# Sobe o Meu Treino completo: Postgres + API + app web.
#
# Se o Flutter SDK estiver instalado, compila o web localmente (rápido).
# Caso contrário, o build acontece dentro do Docker (usa a imagem do Flutter).
set -e
cd "$(dirname "$0")/.."
source scripts/_compose.sh

if [ ! -f .env ]; then
  cp .env.example .env
  echo "-> .env criado a partir de .env.example"
fi

# shellcheck disable=SC1091
set -a; source .env; set +a

if command -v flutter >/dev/null 2>&1; then
  echo "==> Flutter encontrado: compilando o app web localmente"
  (cd app && flutter pub get >/dev/null && flutter build web --release --dart-define=API_BASE_URL=/api)
  export WEB_DOCKERFILE=Dockerfile.prebuilt
else
  echo "==> Flutter não encontrado: o build do web será feito dentro do Docker (pode demorar na 1a vez)"
  export WEB_DOCKERFILE=Dockerfile
fi

echo "==> Construindo as imagens"
$COMPOSE build

echo "==> Subindo os containers"
$COMPOSE up -d

echo "==> Aguardando a API responder"
API_PORT="${API_PORT:-8080}"
for _ in $(seq 1 90); do
  if curl -fsS "http://localhost:${API_PORT}/api/health" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

WEB_PORT="${WEB_PORT:-8081}"
cat <<EOF

=====================================================================
 Meu Treino está no ar

  App .......... http://localhost:${WEB_PORT}
  API .......... http://localhost:${API_PORT}/api
  Swagger ...... http://localhost:${API_PORT}/swagger-ui.html
  Postgres ..... localhost:${DB_PORT:-5433}

  Logs ......... bash scripts/logs.sh
  Parar ........ bash scripts/stop.sh
=====================================================================
EOF
