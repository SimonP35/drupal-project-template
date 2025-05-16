#!/bin/bash
set -e

cd "$( dirname "${BASH_SOURCE[0]}" )"

echo "Loading common file"
source .common

cd ${PROJECT_DIR}

if [[ ${APP_MODE} != 'dev' ]]
then
  echo_info "Download dependencies"
  composer install --no-interaction --no-dev --ignore-platform-reqs
else
  echo_info "Download dev dependencies"
  composer install --no-interaction --ignore-platform-reqs
fi

echo_info "Remove previous translation files"
rm -rf ${APP_DIR}/sites/default/files/translations/*
if [[ ! -d "${APP_DIR}/sites/default/files/translations" ]]
then
  echo_info "Create translation directory"
  mkdir -p ${APP_DIR}/sites/default/files/translations
fi

DRUPAL_CURRENT_VERSION=$(composer show drupal/core | grep versions | sed 's/[^0-9.]*\([0-9.]*\)/\1/')
echo_info "Download Drupal ${DRUPAL_CURRENT_VERSION} translation file"
curl -o ${APP_DIR}/sites/default/files/translations/drupal-${DRUPAL_CURRENT_VERSION}.fr.po https://ftp.drupal.org/files/translations/8.x/drupal/drupal-${DRUPAL_CURRENT_VERSION}.fr.po
