# A Self-Documenting Makefile: http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html

.PHONY: up
up: ## Start the dependencies via docker compose. `export COMPOSE_PROFILES=dev,redis,...`
	$(call print-target)
	docker compose up -d

.PHONY: down
down: ## Stop the dependencies via docker compose
	$(call print-target)
	docker compose down --remove-orphans --volumes

.PHONY: update-openapi
update-openapi: ## Update OpenAPI spec
	$(call print-target)
	dagger call generate openapi -o ./api/openapi.yaml
	dagger call generate openapicloud -o ./api/openapi.cloud.yaml
	go generate ./api/...

.PHONY: gen-api
gen-api: update-openapi ## Generate API and SDKs
	$(call print-target)
	dagger call generate javascript-sdk -o api/client/javascript
	# dagger call generate python-sdk -o api/client/python

.PHONY: migrate-check
migrate-check: ## Validate migrations
	$(call print-target)
	dagger call migrate check

.PHONY: generate
generate: ## Generate code
	$(call print-target)
	go generate ./...

.PHONY: build-server
build-server: ## Build server binary
	$(call print-target)
	go build -o build/server ./cmd/server

.PHONY: build-sink-worker
build-sink-worker: ## Build sink-worker binary
	$(call print-target)
	go build -o build/sink-worker ./cmd/sink-worker

.PHONY: build-benthos-collector
build-benthos-collector: ## Build benthos collector binary
	$(call print-target)
	go build -o build/benthos-collector ./cmd/benthos-collector

.PHONY: build-balance-worker
build-balance-worker: ## Build balance-worker binary
	$(call print-target)
	go build -o build/balance-worker ./cmd/balance-worker

.PHONY: build-billing-worker
build-billing-worker: ## Build billing-worker binary
	$(call print-target)
	go build -o build/billing-worker ./cmd/billing-worker

.PHONY: build-notification-service
build-notification-service: ## Build notification-service binary
	$(call print-target)
	go build -o build/notification-service ./cmd/notification-service

.PHONY: build-jobs
build-jobs: ## Build jobs binary
	$(call print-target)
	go build -o build/jobs ./cmd/jobs

config.yaml:
	cp config.example.yaml config.yaml

.PHONY: server
server: ## Run sink-worker
	@ if [ config.yaml -ot config.example.yaml ]; then diff -u config.yaml config.example.yaml || (echo "!!! The configuration example changed. Please update your config.yaml file accordingly (or at least touch it). !!!" && false); fi
	$(call print-target)
	air -c ./cmd/server/.air.toml

.PHONY: sink-worker
sink-worker: ## Run sink-worker
	@ if [ config.yaml -ot config.example.yaml ]; then diff -u config.yaml config.example.yaml || (echo "!!! The configuration example changed. Please update your config.yaml file accordingly (or at least touch it). !!!" && false); fi
	$(call print-target)
	air -c ./cmd/sink-worker/.air.toml

.PHONY: balance-worker
balance-worker: ## Run balance-worker
	@ if [ config.yaml -ot config.example.yaml ]; then diff -u config.yaml config.example.yaml || (echo "!!! The configuration example changed. Please update your config.yaml file accordingly (or at least touch it). !!!" && false); fi
	$(call print-target)
	air -c ./cmd/balance-worker/.air.toml

.PHONY: billing-worker
billing-worker: ## Run billing-worker
	@ if [ config.yaml -ot config.example.yaml ]; then diff -u config.yaml config.example.yaml || (echo "!!! The configuration example changed. Please update your config.yaml file accordingly (or at least touch it). !!!" && false); fi
	$(call print-target)
	air -c ./cmd/billing-worker/.air.toml

.PHONY: notification-service
notification-service: ## Run notification-service
	@ if [ config.yaml -ot config.example.yaml ]; then diff -u config.yaml config.example.yaml || (echo "!!! The configuration example changed. Please update your config.yaml file accordingly (or at least touch it). !!!" && false); fi
	$(call print-target)
	air -c ./cmd/notification-service/.air.toml

.PHONY: etoe
etoe: ## Run e2e tests
	$(call print-target)
	dagger call etoe

.PHONY: test
test: ## Run tests
	$(call print-target)
	dagger call test

.PHONY: lint
lint: ## Run linters
	$(call print-target)
	dagger call lint all

.PHONY: fmt
fmt: ## Format code
	$(call print-target)
	golangci-lint run --fix

.PHONY: mod
mod: ## go mod tidy
	$(call print-target)
	go mod tidy

.PHONY: seed
seed: ## Seed OpenMeter with test data
	$(call print-target)
	benthos -c etc/seed/seed.yaml

# Helm chart targets
.PHONY: setup-hooks
setup-hooks: ## Setup Git hooks for version management and chart validation
	$(call print-target)
	./setup-hooks.sh

.PHONY: helm-lint
helm-lint: ## Lint Helm chart
	$(call print-target)
	helm lint deploy/charts/openmeter

.PHONY: helm-build
helm-build: ## Build and package Helm chart
	$(call print-target)
	./build.sh

.PHONY: helm-build-latest
helm-build-latest: ## Build and package Helm chart with latest tag
	$(call print-target)
	./build.sh --enable-latest

.PHONY: helm-push
helm-push: ## Push Helm chart to ECR
	$(call print-target)
	./push_to_ecr.sh

.PHONY: helm-push-latest
helm-push-latest: ## Push Helm chart to ECR with latest tag
	$(call print-target)
	./push_to_ecr.sh --enable-latest

.PHONY: helm-deploy
helm-deploy: helm-build helm-push ## Build and deploy Helm chart to ECR
	$(call print-target)
	@echo "Helm chart built and pushed successfully!"

.PHONY: helm-deploy-latest
helm-deploy-latest: helm-build-latest helm-push-latest ## Build and deploy Helm chart to ECR with latest tag
	$(call print-target)
	@echo "Helm chart built and pushed with latest tag successfully!"

.PHONY: helm-test
helm-test: ## Test Helm chart with dry-run
	$(call print-target)
	helm upgrade --install openmeter-test ./deploy/charts/openmeter --dry-run --debug

.PHONY: helm-deps
helm-deps: ## Update Helm chart dependencies
	$(call print-target)
	cd deploy/charts && helm dependency update openmeter

.PHONY: setup-dev
setup-dev: setup-hooks helm-deps ## Setup development environment
	$(call print-target)
	@echo "Development environment setup complete!"

.PHONY: help
.DEFAULT_GOAL := help
help:
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# Variable outputting/exporting rules
var-%: ; @echo $($*)
varexport-%: ; @echo $*=$($*)

define print-target
    @printf "Executing target: \033[36m$@\033[0m\n"
endef
