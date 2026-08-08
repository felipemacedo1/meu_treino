#!/usr/bin/env bash
# =====================================================================
# Publica a API do Meu Treino no Azure Container Apps.
#
# Por que Container Apps: o plano de consumo tem uma cota gratuita mensal
# (180.000 vCPU-s, 360.000 GiB-s e 2 milhoes de requisicoes por assinatura)
# e escala a zero. Para uso pessoal isso normalmente fica dentro do gratuito,
# preservando o credito de US$ 100 do Azure for Students como reserva.
#
# Pre-requisitos:
#   - az CLI logado:            az login
#   - imagem publicada no GHCR: workflow .github/workflows/api-image.yml
#   - banco Postgres acessivel: Neon (gratuito) ou outro
#
# Uso:
#   export DB_URL='jdbc:postgresql://ep-xxx.neon.tech/neondb?sslmode=require'
#   export DB_USER='...'
#   export DB_PASSWORD='...'
#   bash infra/azure/deploy-api.sh
# =====================================================================
set -euo pipefail

RESOURCE_GROUP="${RESOURCE_GROUP:-meu-treino}"
LOCATION="${LOCATION:-brazilsouth}"
ENVIRONMENT="${ENVIRONMENT:-meu-treino-env}"
APP_NAME="${APP_NAME:-meu-treino-api}"
IMAGE="${IMAGE:-ghcr.io/felipemacedo1/meu-treino-api:latest}"
CORS_ALLOWED_ORIGINS="${CORS_ALLOWED_ORIGINS:-*}"

for var in DB_URL DB_USER DB_PASSWORD; do
  if [ -z "${!var:-}" ]; then
    echo "Falta a variavel $var. Veja o cabecalho deste script." >&2
    exit 1
  fi
done

# Segredo do JWT: gera um se nao vier de fora, e mostra no fim.
JWT_SECRET="${JWT_SECRET:-$(head -c 48 /dev/urandom | base64 | tr -d '\n=+/')}"

echo "==> Registrando os providers necessarios (idempotente)"
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait

echo "==> Extensao containerapp"
az extension add --name containerapp --upgrade --only-show-errors

echo "==> Resource group $RESOURCE_GROUP em $LOCATION"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --only-show-errors >/dev/null

echo "==> Ambiente do Container Apps"
if ! az containerapp env show -g "$RESOURCE_GROUP" -n "$ENVIRONMENT" >/dev/null 2>&1; then
  az containerapp env create \
    --name "$ENVIRONMENT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --only-show-errors >/dev/null
fi

echo "==> Aplicacao $APP_NAME"
# --min-replicas 0 = escala a zero quando ninguem usa (mantem no gratuito).
# Custa um cold start de alguns segundos na primeira requisicao.
# Para sempre ligado, troque para --min-replicas 1 (sai da cota gratuita e
# passa a consumir o credito).
COMMON_ARGS=(
  --name "$APP_NAME"
  --resource-group "$RESOURCE_GROUP"
  --image "$IMAGE"
  --target-port 8080
  --ingress external
  --cpu 0.5 --memory 1.0Gi
  --min-replicas 0 --max-replicas 1
  --secrets "db-password=$DB_PASSWORD" "jwt-secret=$JWT_SECRET"
  --env-vars
    "DB_URL=$DB_URL"
    "DB_USER=$DB_USER"
    "DB_PASSWORD=secretref:db-password"
    "JWT_SECRET=secretref:jwt-secret"
    "CORS_ALLOWED_ORIGINS=$CORS_ALLOWED_ORIGINS"
    "WGER_SYNC_ON_STARTUP=false"
    "JAVA_OPTS=-XX:MaxRAMPercentage=70 -XX:+UseSerialGC -Xss512k"
    "TZ=America/Sao_Paulo"
)

if az containerapp show -g "$RESOURCE_GROUP" -n "$APP_NAME" >/dev/null 2>&1; then
  az containerapp update "${COMMON_ARGS[@]}" --only-show-errors >/dev/null
else
  az containerapp create "${COMMON_ARGS[@]}" \
    --environment "$ENVIRONMENT" \
    --only-show-errors >/dev/null
fi

FQDN="$(az containerapp show -g "$RESOURCE_GROUP" -n "$APP_NAME" \
  --query properties.configuration.ingress.fqdn -o tsv)"
API_URL="https://$FQDN"

echo "==> Aguardando a API responder (o primeiro boot roda as migrations)"
for _ in $(seq 1 60); do
  if curl -fsS "$API_URL/api/health" >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

cat <<EOF

=====================================================================
 API no ar

  URL .......... $API_URL
  Health ....... $API_URL/api/health
  Swagger ...... $API_URL/swagger-ui.html

  JWT_SECRET gerado (guarde; trocar invalida os logins existentes):
  $JWT_SECRET

 Proximos passos:

  1) App web (Static Web Apps), apontando para esta API:
       cd app && flutter build web --release \\
         --dart-define=API_BASE_URL=$API_URL/api

  2) Restrinja o CORS ao dominio do app depois de publicar:
       az containerapp update -g $RESOURCE_GROUP -n $APP_NAME \\
         --set-env-vars CORS_ALLOWED_ORIGINS=https://SEU-APP.azurestaticapps.net

  3) No APK: tela de login > Servidor > $API_URL/api

  Logs:  az containerapp logs show -g $RESOURCE_GROUP -n $APP_NAME --follow
=====================================================================
EOF
