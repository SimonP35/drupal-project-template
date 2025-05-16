OS_INFORMATION=$(shell uname -s)
ifneq (,$(findstring Linux,$(OS_INFORMATION)))
OS_NAME = linux
endif

ifneq (,$(findstring Darwin,$(OS_INFORMATION)))
OS_NAME = mac
endif

ifneq (,$(findstring CYGWIN,$(OS_INFORMATION)))
OS_NAME = win
endif

ifneq (,$(findstring MINGW,$(OS_INFORMATION)))
OS_NAME = win
endif

DOCKER_COMPOSE_FILES := -f docker-compose.yml
ifneq ("$(wildcard docker-compose-${OS_NAME}.yml)","")
DOCKER_COMPOSE_FILES := $(DOCKER_COMPOSE_FILES) -f docker-compose-${OS_NAME}.yml
endif

ifneq ("$(wildcard docker-compose-local.yml)","")
DOCKER_COMPOSE_FILES := $(DOCKER_COMPOSE_FILES) -f docker-compose-local.yml
endif

DOCKER_COMPOSE = docker compose ${DOCKER_COMPOSE_FILES}
DOCKER_COMPOSE_TOOLS = ${DOCKER_COMPOSE} -f docker-compose-tools.yml
EXEC_PHP = $(DOCKER_COMPOSE) exec php
DRUSH = $(EXEC_PHP) drush
COMPOSER = $(EXEC_PHP) composer
EXEC_THEME = $(DOCKER_COMPOSE_TOOLS) run --rm theme
EXEC_SECURITY = $(DOCKER_COMPOSE_TOOLS) run --rm security

.env:
ifeq (,$(wildcard ./.env))
	cp .env.dist .env
endif

##
## Project
## -------
##

build: ## Build project dependencies.
build: .env	start
	$(EXEC_PHP) sh -c "./automation/bin/build.sh"


kill: ## Kill all docker containers.
kill:
	$(DOCKER_COMPOSE) kill
	$(DOCKER_COMPOSE) down --volumes --remove-orphans

install: ## Start docker stack and install the project.
install: .env start
	$(EXEC_PHP) sh -c "./automation/bin/install.sh"
	$(EXEC_PHP) sh -c "./automation/bin/reset_password.sh"

update: ## Start docker stack and update the project.
update: .env	start
	$(EXEC_PHP) sh -c "./automation/bin/update.sh"

setup:  ## Start docker stack, build and install the project.
setup: .env build install

reset: ## Kill all docker containers and start a fresh install of the project.
reset: kill setup

start: update-permissions ## Start the project.
	$(DOCKER_COMPOSE) up -d --remove-orphans
	$(DOCKER_COMPOSE) exec -u 0 php sh -c "if [ -d /var/www/html/web/sites/default ]; then chmod -R a+w /var/www/html/web/sites/default; fi"
	$(DOCKER_COMPOSE) exec -u 0 php sh -c "if [ -d /tmp/cache ]; then chmod -R a+w /tmp/cache; fi"


reset_password: ## Reset the Drupal password to "admin".
	$(EXEC_PHP) sh -c "./automation/bin/reset_password.sh"

update-permissions: ## Fix permissions between Docker and the host.
ifeq ($(OS_NAME), linux)
update-permissions:
	sudo setfacl -dR -m u:$(shell whoami):rwX -m u:82:rwX -m u:1000:rwX .
	sudo setfacl -R -m u:$(shell whoami):rwX -m u:82:rwX -m u:1000:rwX .
else ifeq ($(OS_NAME), mac)
update-permissions:
	sudo dseditgroup -o edit -a $(shell id -un) -t user $(shell id -gn 82)
endif

stop: ## Stop all docker containers.
	$(DOCKER_COMPOSE) stop

clean: ## Kill all docker containers and remove generated files
clean: kill
	rm -rf .env vendor web/core web/modules/contrib web/themes/contrib web/profiles/contrib

ifeq (console,$(firstword $(MAKECMDGOALS)))
  CONSOLE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(CONSOLE_ARGS):;@:)
endif
console: ## Open a console in the container passed in argument (e.g make console php)
	$(DOCKER_COMPOSE) exec $(CONSOLE_ARGS) bash

ifeq (theme,$(firstword $(MAKECMDGOALS)))
  THEME_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(THEME_ARGS):;@:)
endif
theme: ## Execute a theme command inside node container (e.g: make theme "node -v")
	$(EXEC_THEME) $(THEME_ARGS)

.PHONY: build setup kill install update reset reset_password start stop clean console update-permissions setup-theme theme

##
## Utils
## -----
##
logs: ## Show Drupal logs.
	$(DRUSH) ws

cr: ## Rebuild Drupal caches.
	$(DRUSH) cache:rebuild

cex: ## Export Drupal configuration.
	$(DRUSH) config-split:export -y

cim: ## Import Drupal configuration.
	$(DRUSH) config-split:import -y

ifeq (composer,$(firstword $(MAKECMDGOALS)))
  COMPOSER_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMPOSER_ARGS):;@:)
endif
composer: ## Execute a composer command inside PHP container (e.g: make composer require drupal/paragraphs)
	$(COMPOSER) $(COMPOSER_ARGS)

browsersync-start: ## Start the browsersync server
	$(DOCKER_COMPOSE_TOOLS) run --rm browsersync -c ./config.js

.PHONY: logs cr cex composer

##
## Quality assurance
## -----------------
##
phpcs: ## Run PHP Code Sniffer using the phpcs.xml ruleset.
	$(EXEC_PHP) vendor/bin/phpcs

phpstan: ## Run PHPStan using the phpstan.neon ruleset.
	$(EXEC_PHP) vendor/bin/phpstan analyse -c phpstan.neon --memory-limit=-1

phpmd: ## Run PHP Mess Detector using the phpmd.rules.xml ruleset.
	$(EXEC_PHP) vendor/bin/phpmd ./web/modules/custom,./web/themes/custom,./web/profiles/custom text phpmd.xml

phpcpd: ## Run PHP Copy Paste Detector.
	$(EXEC_PHP) vendor/bin/phpcpd ./web/modules/custom ./web/themes/custom ./web/profiles/custom

security_check: ## Run vulnerabilities check.
	$(EXEC_SECURITY) --exit-code 1 fs --security-checks vuln /app

.PHONY: phpcs phpstan phpmd phpcpd security_check

.DEFAULT_GOAL := help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
.PHONY: help
