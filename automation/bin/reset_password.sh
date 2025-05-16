#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

echo "Loading common file"
source .common

cd ${APP_DIR}

${DRUSH} user-password admin admin