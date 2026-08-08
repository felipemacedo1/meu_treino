#!/usr/bin/env bash
set -e

# Espera pelo Postgres apenas quando ele sobe junto com a API (docker compose,
# que define DB_HOST=db). Com banco gerenciado (Neon, Azure, RDS...) DB_HOST
# nao e definido: esperar ali so desperdiçaria o tempo de boot, porque o host
# externo ja esta no ar e o Hikari/Flyway tratam a reconexao.
if [ -n "${DB_HOST:-}" ]; then
  DB_PORT_INTERNAL="${DB_PORT_INTERNAL:-5432}"
  DB_USER="${DB_USER:-meutreino}"

  echo "Aguardando o Postgres em ${DB_HOST}:${DB_PORT_INTERNAL}..."
  for _ in $(seq 1 60); do
    if pg_isready -h "$DB_HOST" -p "$DB_PORT_INTERNAL" -U "$DB_USER" >/dev/null 2>&1; then
      echo "Postgres pronto."
      break
    fi
    sleep 2
  done
else
  echo "DB_HOST nao definido: assumindo banco gerenciado, iniciando direto."
fi

exec java $JAVA_OPTS -jar /app/app.jar
