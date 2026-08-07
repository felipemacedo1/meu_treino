#!/usr/bin/env bash
set -e

DB_HOST="${DB_HOST:-db}"
DB_PORT_INTERNAL="${DB_PORT_INTERNAL:-5432}"
DB_USER="${DB_USER:-meutreino}"

echo "Aguardando o Postgres em ${DB_HOST}:${DB_PORT_INTERNAL}..."
for i in $(seq 1 60); do
  if pg_isready -h "$DB_HOST" -p "$DB_PORT_INTERNAL" -U "$DB_USER" >/dev/null 2>&1; then
    echo "Postgres pronto."
    break
  fi
  sleep 2
done

exec java $JAVA_OPTS -jar /app/app.jar
