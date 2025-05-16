# Drupal Project Makefile
#
# This Makefile provides commands to manage a Drupal project with Docker.
# Use 'make help' to see all available commands.

.DEFAULT_GOAL := help

# OS detection
OS_INFORMATION := $(shell uname -s)

ifeq ($(findstring Linux,$(OS_INFORMATION)),Linux)
  OS_NAME := linux
else ifeq ($(findstring Darwin,$(OS_INFORMATION)),Darwin)
  OS_NAME := mac
else ifeq ($(findstring CYGWIN,$(OS_INFORMATION)),CYGWIN)
  OS_NAME := win
else ifeq ($(findstring MINGW,$(OS_INFORMATION)),MINGW)
  OS_NAME := win
endif

# Docker Compose configuration
DOCKER_COMPOSE_FILES := -f docker-compose.yml

ifneq ("$(wildcard docker-compose-${OS_NAME}.yml)","")
  DOCKER_COMPOSE_FILES += -f docker-compose-${OS_NAME}.yml
endif

ifneq ("$(wildcard docker-compose-local.yml)","")
  DOCKER_COMPOSE_FILES += -f docker-compose-local.yml
endif

# Docker commands
DOCKER_COMPOSE        := docker compose ${DOCKER_COMPOSE_FILES}
DOCKER_COMPOSE_TOOLS  := ${DOCKER_COMPOSE} -f docker-compose-tools.yml
EXEC_PHP              := $(DOCKER_COMPOSE) exec php
DRUSH                 := $(EXEC_PHP) drush
COMPOSER              := $(EXEC_PHP) composer
EXEC_THEME            := $(DOCKER_COMPOSE_TOOLS) run --rm theme
EXEC_SECURITY         := $(DOCKER_COMPOSE_TOOLS) run --rm security

# Create .env file if it doesn't exist
.env:
ifeq (,$(wildcard ./.env))
	cp .env.dist .env
endif

# Project commands

## Project management

start: update-permissions ## Start the project
	$(DOCKER_COMPOSE) up -d --remove-orphans
	$(DOCKER_COMPOSE) exec -u 0 php sh -c "if [ -d /var/www/html/web/sites/default ]; then chmod -R a+w /var/www/html/web/sites/default; fi"
	$(DOCKER_COMPOSE) exec -u 0 php sh -c "if [ -d /tmp/cache ]; then chmod -R a+w /tmp/cache; fi"

stop: ## Stop all Docker containers
	$(DOCKER_COMPOSE) stop

kill: ## Kill all Docker containers
	$(DOCKER_COMPOSE) kill
	$(DOCKER_COMPOSE) down --volumes --remove-orphans

build: .env start ## Build project dependencies
	$(EXEC_PHP) sh -c "./automation/bin/build.sh"

install: .env start ## Start Docker stack and install the project
	$(EXEC_PHP) sh -c "./automation/bin/install.sh"
	$(EXEC_PHP) sh -c "./automation/bin/reset_password.sh"

update: .env start ## Start Docker stack and update the project
	$(EXEC_PHP) sh -c "./automation/bin/update.sh"

setup: .env build install ## Start Docker stack, build and install the project

reset: kill setup ## Kill all Docker containers and start a fresh install

reset_password: ## Reset Drupal password to "admin"
	$(EXEC_PHP) sh -c "./automation/bin/reset_password.sh"

clean: kill ## Kill all Docker containers and remove generated files
	rm -rf .env vendor web/core web/modules/contrib web/themes/contrib web/profiles/contrib

## Permissions management

update-permissions: ## Fix permissions between Docker and host
ifeq ($(OS_NAME), linux)
	sudo setfacl -dR -m u:$(shell whoami):rwX -m u:82:rwX -m u:1000:rwX .
	sudo setfacl -R -m u:$(shell whoami):rwX -m u:82:rwX -m u:1000:rwX .
else ifeq ($(OS_NAME), mac)
	sudo dseditgroup -o edit -a $(shell id -un) -t user $(shell id -gn 82)
endif

# Drupal commands

## Drupal utilities

cr: ## Rebuild Drupal caches
	$(DRUSH) cache:rebuild

cex: ## Export Drupal configuration
	$(DRUSH) config-split:export -y

cim: ## Import Drupal configuration
	$(DRUSH) config-split:import -y

logs: ## Show Drupal logs
	$(DRUSH) ws

# Utility commands

## Console commands

# Handle arguments for console command
ifeq (console,$(firstword $(MAKECMDGOALS)))
  CONSOLE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(CONSOLE_ARGS):;@:)
endif

console: ## Open a console in the specified container (e.g., make console php)
	$(DOCKER_COMPOSE) exec $(CONSOLE_ARGS) bash

# Handle arguments for theme command
ifeq (theme,$(firstword $(MAKECMDGOALS)))
  THEME_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(THEME_ARGS):;@:)
endif

theme: ## Execute a theme command in the node container (e.g., make theme "node -v")
	$(EXEC_THEME) $(THEME_ARGS)

# Handle arguments for composer command
ifeq (composer,$(firstword $(MAKECMDGOALS)))
  COMPOSER_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMPOSER_ARGS):;@:)
endif

composer: ## Execute a composer command in the PHP container (e.g., make composer require drupal/paragraphs)
	$(COMPOSER) $(COMPOSER_ARGS)

browsersync-start: ## Start the browsersync server
	$(DOCKER_COMPOSE_TOOLS) run --rm browsersync -c ./config.js

# Quality assurance

## Code quality tools

phpcs: ## Run PHP Code Sniffer with phpcs.xml ruleset
	$(EXEC_PHP) vendor/bin/phpcs

phpstan: ## Run PHPStan with phpstan.neon ruleset
	$(EXEC_PHP) vendor/bin/phpstan analyse -c phpstan.neon --memory-limit=-1

phpmd: ## Run PHP Mess Detector with phpmd.xml ruleset
	$(EXEC_PHP) vendor/bin/phpmd ./web/modules/custom,./web/themes/custom,./web/profiles/custom text phpmd.xml

phpcpd: ## Run PHP Copy Paste Detector
	$(EXEC_PHP) vendor/bin/phpcpd ./web/modules/custom ./web/themes/custom ./web/profiles/custom

security_check: ## Run vulnerability check
	$(EXEC_SECURITY) --exit-code 1 fs --security-checks vuln /app

# Help

help: ## Display help information
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

# .PHONY targets declaration
.PHONY: help build setup kill install update reset reset_password start stop clean \
        console update-permissions theme logs cr cex cim composer browsersync-start \
        phpcs phpstan phpmd phpcpd security_check
