#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_generate_full() {
    run_script 'env_update'
    info "Enabling all apps."
    sed -i 's/_ENABLED=false/_ENABLED=true/' "${SCRIPTPATH}/compose/.env"
    info "Adjusting ports to prevent conflicts."
    run_script 'env_set' "DELUGEVPN_PORT_58846" "58847"
    run_script 'env_set' "DELUGEVPN_PORT_58946" "58947"
    run_script 'env_set' "DELUGEVPN_PORT_8112" "18112"
    run_script 'env_set' "GUACAMOLE_PORT_8080" "48080"
    run_script 'env_set' "HEADPHONES_PORT_8181" "18181"
    run_script 'env_set' "MARIADB_PORT_3306" "13306"
    run_script 'env_set' "MCMYADMIN2_PORT_8080" "48080"
    run_script 'env_set' "MEDUSA_PORT_8081" "18081"
    run_script 'env_set' "MYLAR_PORT_8090" "18090"
    run_script 'env_set' "PLEXREQUESTS_PORT_3000" "13000"
    run_script 'env_set' "QBITTORRENT_PORT_6881" "16881"
    run_script 'env_set' "QBITTORRENT_PORT_8080" "18080"
    run_script 'env_set' "SABNZBD_PORT_8080" "28080"
    run_script 'env_set' "SABNZBDVPN_PORT_8080" "38080"
    run_script 'env_set' "SICKRAGE_PORT_8081" "28081"
    run_script 'env_set' "THELOUNGE_PORT_9000" "9002"
    run_script 'env_set' "TRAEFIK_PORT_8080" "58080"
    run_script 'env_set' "TRANSMISSION_PORT_51413" "51414"
    run_script 'env_set' "TRANSMISSION_PORT_9091" "19091"
    run_script 'env_set' "UNIFI_PORT_6789" "16789"
    run_script 'env_set' "UNIFI_PORT_7878" "17878"
    run_test 'run_generate_slim'
}
