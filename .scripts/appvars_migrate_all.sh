#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_migrate_all() {
    if grep -q -P '_ENABLED='"'"'?true'"'"'?$' "${COMPOSE_ENV}"; then
        if grep -q -P '\b(?!(COMPOSE_|DOCKER_|DOCKERLOGGING_|LAN_|VPN_))[A-Z0-9]+_(?!(ENABLED|ENVIRONMENT_|NETWORK_MODE|PORT_|RESTART|TAG|VOLUME_))' "${COMPOSE_ENV}"; then
            notice "Migrating environment variables for enabled apps. Please be patient, this can take a while."
            while IFS= read -r line; do
                local APPNAME=${line%%_ENABLED=*}
                if grep -q -P "\b${APPNAME}_(?!(ENABLED|ENVIRONMENT_|NETWORK_MODE|PORT_|RESTART|TAG|VOLUME_))" "${COMPOSE_ENV}"; then
                    run_script 'appvars_migrate' "${APPNAME}"
                    info "Environment variables migrated for ${APPNAME}."
                fi
            done < <(grep --color=never -P '_ENABLED='"'"'?true'"'"'?$' "${COMPOSE_ENV}")
        fi
    fi
}

test_appvars_migrate_all() {
    # run_script 'appvars_migrate_all'
    warn "CI does not test appvars_migrate_all."
}
