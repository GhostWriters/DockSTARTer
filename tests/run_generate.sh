#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_generate() {
    run_script 'update_system'
    run_script 'env_create'
    info "Enabling all apps."
    sed -i 's/_ENABLED=false/_ENABLED=true/' "${SCRIPTPATH}/compose/.env"
    info "Adjusting ports to prevent conflicts."
    run_script 'env_set' "DELUGEVPN_PORT_58846" "58847"
    run_script 'env_set' "DELUGEVPN_PORT_58946" "58947"
    run_script 'env_set' "DELUGEVPN_PORT_8112" "18112"
    run_script 'env_set' "HEADPHONES_PORT_8181" "18181"
    run_script 'env_set' "PLEX_PORT_1900" "11900"
    run_script 'env_set' "PLEXREQUESTS_PORT_3000" "13000"
    run_script 'env_set' "RUTORRENT_PORT_51413" "41413"
    run_script 'env_set' "RUTORRENT_PORT_6881" "16881"
    run_script 'env_set' "SICKRAGE_PORT_8081" "28081"
    run_script 'env_set' "TRANSMISSIONVPN_PORT_9091" "19091"
    run_script 'env_set' "UNIFI_PORT_6789" "16789"
    run_script 'env_set' "UNIFI_PORT_7878" "17878"
    run_script 'env_set' "UNIFI_PORT_8080" "18080"
    run_script 'env_set' "UNIFI_PORT_8081" "18081"
    info "Running generator."
    bash "${SCRIPTPATH}/main.sh" -g
    echo
    cat "${SCRIPTPATH}/compose/docker-compose.yml" || fatal "${SCRIPTPATH}/compose/docker-compose.yml not found."
    echo
    cd "${SCRIPTPATH}/compose/" || fatal "Could not change to ${SCRIPTPATH}/compose/ directory."
    docker-compose up -d || fatal "Docker Compose failed."
    cd "${SCRIPTPATH}" || fatal "Could not change to ${SCRIPTPATH} directory."
}
