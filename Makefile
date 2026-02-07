# Tostada - Phoenix + SvelteKit Boilerplate
# Run `make help` to see available commands

.PHONY: help install install.server install.client dev dev.server dev.client dev.logs dev.logs.clear \
        db.create db.drop db.migrate db.rollback db.reset db.setup \
        test test.server test.client lint lint.fix typecheck \
        build build.client build.server assets.deploy \
        models.build models.clean \
        deploy.build deploy.release deploy.full \
        clean clean.deps

# Colors for output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RESET := \033[0m

help: ## Show this help
	@echo "$(CYAN)Tostada$(RESET)"
	@echo ""
	@echo "$(GREEN)Available commands:$(RESET)"
	@grep -E '^[a-zA-Z_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-22s$(RESET) %s\n", $$1, $$2}'

# =============================================================================
# Installation
# =============================================================================

install: ## Install dependencies for both server and client
	cd server && mix deps.get
	cd client && npm install

install.server: ## Install server dependencies only
	cd server && mix deps.get

install.client: ## Install client dependencies only
	cd client && npm install

# =============================================================================
# Development
# =============================================================================

dev: ## Start both server and client (requires tmux). Logs to logs/
	@mkdir -p logs
	@if command -v tmux >/dev/null 2>&1; then \
		tmux new-session -d -s tostada "cd server && mix phx.server 2>&1 | tee -a ../logs/server.log" \; \
		split-window -h "cd client && npm run dev 2>&1 | tee -a ../logs/client.log" \; \
		attach; \
	else \
		echo "$(YELLOW)tmux not installed. Run these in separate terminals:$(RESET)"; \
		echo "  make dev.server"; \
		echo "  make dev.client"; \
	fi

dev.server: ## Start Phoenix server (logs to logs/server.log)
	@mkdir -p logs
	cd server && mix phx.server 2>&1 | tee -a ../logs/server.log

dev.client: ## Start SvelteKit client
	cd client && npm run dev

dev.logs: ## Tail the server log
	tail -f logs/server.log

dev.logs.clear: ## Clear dev logs
	@rm -f logs/server.log logs/client.log
	@echo "$(GREEN)Logs cleared$(RESET)"

# =============================================================================
# Database
# =============================================================================

db.create: ## Create the database
	cd server && mix ecto.create

db.drop: ## Drop the database
	cd server && mix ecto.drop

db.migrate: ## Run migrations
	cd server && mix ecto.migrate

db.rollback: ## Rollback last migration
	cd server && mix ecto.rollback

db.reset: ## Reset the database (drop + create + migrate + seed)
	cd server && mix ecto.reset

db.setup: ## Setup database and load seeds
	cd server && mix ecto.setup

# =============================================================================
# Testing & Linting
# =============================================================================

test: ## Run all tests (server + client unit tests)
	cd server && mix test
	cd client && npm run test

test.server: ## Run server tests only
	cd server && mix test

test.client: ## Run client unit tests
	cd client && npm run test

lint: ## Run linters on both server and client
	cd server && mix format --check-formatted
	cd client && npm run check

lint.fix: ## Auto-fix linting issues
	cd server && mix format
	cd client && npm run check

typecheck: ## Run TypeScript type checking
	cd client && npm run check

# =============================================================================
# Build
# =============================================================================

build: ## Build client + server assets for production
	cd server && MIX_ENV=prod mix compile
	cd client && npm run prebuild
	cd client && npm run build
	cd server && MIX_ENV=prod mix assets.deploy

build.client: ## Build client only
	cd client && npm run prebuild
	cd client && npm run build

build.server: ## Build Phoenix assets only
	cd server && MIX_ENV=prod mix assets.deploy

assets.deploy: ## Run Phoenix asset pipeline (tailwind/esbuild + digest)
	cd server && MIX_ENV=prod mix assets.deploy

# =============================================================================
# Models (optional pipeline)
# =============================================================================

models.build: ## Build GLTF/GLB models into client static assets
	./scripts/build-models.sh

models.clean: ## Remove generated model outputs
	rm -rf client/src/lib/models/generated client/src/lib/models/generated-registry.ts client/static/models

# =============================================================================
# Deployment
# =============================================================================

deploy.build: ## Build a production release (server/scripts/deploy/build.sh)
	APP_NAME=$(APP_NAME) ./server/scripts/deploy/build.sh

deploy.release: ## Run migrations + restart (server/scripts/deploy/deploy.sh)
	APP_NAME=$(APP_NAME) APP_MODULE=$(APP_MODULE) ./server/scripts/deploy/deploy.sh

deploy.full: ## Pull + build + deploy (server/scripts/deploy/full-deploy.sh)
	./server/scripts/deploy/full-deploy.sh

# =============================================================================
# Cleanup
# =============================================================================

clean: ## Clean build artifacts
	cd server && mix clean
	cd client && rm -rf .svelte-kit build

clean.deps: ## Remove all dependencies
	cd server && rm -rf deps _build
	cd client && rm -rf node_modules
