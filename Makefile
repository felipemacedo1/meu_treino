.DEFAULT_GOAL := help
SHELL := /bin/bash

.PHONY: help up down logs restart db api web smoke sync reset build test clean

help: ## Mostra os comandos disponíveis
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

up: ## Sobe tudo (Postgres + API + app web)
	@bash scripts/start.sh

down: ## Para todos os containers
	@bash scripts/stop.sh

logs: ## Logs da API (make logs s=web para o nginx)
	@bash scripts/logs.sh $(or $(s),api)

restart: down up ## Reinicia a stack

db: ## Sobe apenas o Postgres
	@bash scripts/db-up.sh

api: ## Roda o backend localmente com Maven (precisa do Postgres no ar)
	@bash scripts/run-backend.sh

web: ## Roda o app Flutter no Chrome em modo dev
	@cd app && flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api

smoke: ## Teste de fumaça do backend (fluxo completo)
	@bash scripts/smoke-test.sh

sync: ## Sincroniza o catálogo com o wger (make sync e=email p=senha)
	@bash scripts/sync-exercises.sh $(e) $(p)

build: ## Compila backend (jar) e app web
	@cd backend && mvn -B -DskipTests package
	@cd app && flutter build web --release --dart-define=API_BASE_URL=/api

test: ## Testes do backend
	@cd backend && mvn -B test

reset: ## APAGA o banco e recria do zero
	@bash scripts/reset-db.sh

clean: ## Limpa artefatos de build
	@cd backend && mvn -q clean
	@cd app && flutter clean
