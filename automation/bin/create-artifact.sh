#!/bin/bash
set -e

cd "$( dirname "${BASH_SOURCE[0]}" )"

echo "Loading common file"
source .common

cd ${PROJECT_DIR}

printf "{\"time\":\"%s\",\"hash\":\"%s\",\"tag\":\"%s\"}" `date -u +%Y-%m-%dT%H:%M:%SZ` ${CI_COMMIT_SHA} ${CI_COMMIT_REF_SLUG} > ./web/version.json
tar \
  --exclude-vcs \
  --exclude='automation/docker' \
  --exclude='automation/gce' \
  --exclude='automation/gke' \
  --exclude='docs' \
  --exclude='docker*.yml' \
  --exclude='docker*.yml.dist' \
  --exclude='Makefile' \
  --exclude='phpcs.xml.dist' \
  --exclude='phpmd.rules.xml' \
  --exclude='phpstan.neon.dist' \
  --exclude='README.md' \
  --exclude='web/themes/default/browsersync' \
  --exclude='web/themes/default/README.md' \
  --exclude='web/themes/default/index.html' \
  -zcf ./artifact.tar.gz *
