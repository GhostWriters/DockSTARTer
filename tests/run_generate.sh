#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_generate() {
    info "Copying .env file from example."
    cp "${SCRIPTPATH}/compose/.env.example" "${SCRIPTPATH}/compose/.env"
    info "Enabling all apps."
    sed -i 's/_ENABLED=false/_ENABLED=true/' "${SCRIPTPATH}/compose/.env"
    info "Adjusting ports to prevent conflicts."
    sed -i 's/DELUGEVPN_PORT_58846=58846/DELUGEVPN_PORT_58846=58847/' "${SCRIPTPATH}/compose/.env"
    sed -i 's/DELUGEVPN_PORT_58946=58946/DELUGEVPN_PORT_58946=58947/' "${SCRIPTPATH}/compose/.env"
    sed -i 's/DELUGEVPN_PORT_8112=8112/DELUGEVPN_PORT_8112=18112/' "${SCRIPTPATH}/compose/.env"
    sed -i 's/HEADPHONES_PORT_8181=8181/HEADPHONES_PORT_8181=18181/' "${SCRIPTPATH}/compose/.env"
    sed -i 's/PLEX_PORT_1900=1900/PLEX_PORT_1900=11900/' "${SCRIPTPATH}/compose/.env"
    sed -i 's/RUTORRENT_PORT_51413=51413/RUTORRENT_PORT_51413=41413/' "${SCRIPTPATH}/compose/.env"
    sed -i 's/RUTORRENT_PORT_6881=6881/RUTORRENT_PORT_6881=16881/' "${SCRIPTPATH}/compose/.env"
    sed -i 's/TRANSMISSIONVPN_PORT_9091=9091/TRANSMISSIONVPN_PORT_9091=19091/' "${SCRIPTPATH}/compose/.env"
    sed -i 's/UNIFI_PORT_6789=6789/UNIFI_PORT_6789=16789/' "${SCRIPTPATH}/compose/.env"
    sed -i 's/UNIFI_PORT_7878=7878/UNIFI_PORT_7878=17878/' "${SCRIPTPATH}/compose/.env"
    sed -i 's/UNIFI_PORT_8080=8080/UNIFI_PORT_8080=18080/' "${SCRIPTPATH}/compose/.env"
    sed -i 's/UNIFI_PORT_8081=8081/UNIFI_PORT_8081=18081/' "${SCRIPTPATH}/compose/.env"
    info "Running generator."
    bash "${SCRIPTPATH}/main.sh" -g
    echo
    cat "${SCRIPTPATH}/compose/docker-compose.yml" || fatal "${SCRIPTPATH}/compose/docker-compose.yml not found."
    echo
    cd "${SCRIPTPATH}/compose/" || fatal "Could not change to ${SCRIPTPATH}/compose/ directory."
    docker-compose up -d || fatal "Docker Compose failed."
    cd "${SCRIPTPATH}" || fatal "Could not change to ${SCRIPTPATH} directory."
}
