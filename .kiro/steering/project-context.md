# Project Context - Meu Treino

## Overview

Aplicativo de musculação para uso pessoal, **implementado e funcionando**.

- Backend: Spring Boot 3.5 + Java 21 + PostgreSQL 16 + Flyway + JWT (pasta `backend/`)
- App: Flutter (web/PWA + Android), Riverpod + go_router + Dio (pasta `app/`)
- Catálogo: 834 exercícios do wger já dentro do banco (migration `V3`)
- Sobe tudo com `make up` (docker compose: db + api + web)

## Repository

- Owner: felipemacedo1
- Repo: https://github.com/felipemacedo1/meu_treino (existe, remoto `origin` via SSH)
- Branch principal: `main`

## Workspace

- Path: /home/felipe-macedo/projects/meu_treino
- Git inicializado, remoto configurado
- gh CLI autenticado como felipemacedo1

## Como rodar

```bash
make up      # Postgres + API + app web
make smoke   # teste de fumaça do backend (fluxo completo)
make logs    # logs da API
make down    # para tudo
```

- App: http://localhost:8081
- API: http://localhost:8080/api · Swagger em /swagger-ui.html
- Postgres: localhost:5433 (meutreino/meutreino)

## Convenções

- Backend organizado por feature em `com.meutreino.<area>` (controller + service + repository + dto)
- Migrations Flyway em `backend/src/main/resources/db/migration` (nunca editar uma já aplicada; criar `V7`, `V8`…)
- App em `app/lib/src/{core,models,data,providers,features,widgets}`
- Textos de UI em português
- Detalhes das decisões técnicas em `docs/ARQUITETURA.md`

## Ambiente local (observações)

- `docker compose` v2 instalado em `~/.docker/cli-plugins` (o v1 quebra com Docker >= 25);
  reinstalar com `bash scripts/install-compose-v2.sh` se necessário
- Flutter 3.38.6 instalado; Android SDK sem cmdline-tools (build de APK precisa instalar)
- Porta 5432 do host está ocupada por outro projeto, por isso o Postgres usa 5433
