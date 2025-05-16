#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

source .common

echo_info "Update DRUPAL"

cd ${APP_DIR}

${DRUSH} state-set system.maintenance_mode 1 || error

${DRUSH} updatedb -y || error
${DRUSH} config:import -y || error

${DRUSH} state-set system.maintenance_mode 0 || error

${DRUSH} cr

echo_info "Install DRUPAL Finished"
