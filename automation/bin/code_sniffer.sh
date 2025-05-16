#!/usr/bin/env sh

DIR=$( cd ${0%/*} && pwd -P )
cd ${DIR}
PROJECT_DIR=${DIR}/../..
APP_DIR=${PROJECT_DIR}/web

phpcs \
--standard=Drupal,DrupalPractice \
--extensions=php,module,inc,install,test,profile,theme,css,info,txt,md \
--ignore="*/node_modules/*,*/themes/*/css/*" \
--report=json \
--report-file=${PROJECT_DIR}/phpcs.json \
${APP_DIR}/profiles/custom ${APP_DIR}/modules/custom ${APP_DIR}/themes/custom
