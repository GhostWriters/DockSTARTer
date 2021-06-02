#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

docker_compose() {
    local COMPOSEINPUT=${1:-}
    local COMMAND=${COMPOSEINPUT%% *}
    local APPNAME
    if [[ ${COMPOSEINPUT} == *" "* ]]; then
        APPNAME=${COMPOSEINPUT#* }
    fi
    local COMPOSECOMMAND
    local COMMANDINFO
    case ${COMMAND} in
        down)
            COMPOSECOMMAND="down --remove-orphans"
            COMMANDINFO="Stopping and removing containers, networks, volumes, and images created by DockSTARTer."
            ;;
        pull)
            COMPOSECOMMAND="pull --include-deps ${APPNAME:-}"
            COMMANDINFO="Pulling the latest images for ${APPNAME:-all enabled services}."
            ;;
        restart)
            COMPOSECOMMAND="restart ${APPNAME:-}"
            COMMANDINFO="Restarting ${APPNAME:-all stopped and running services}."
            ;;
        up)
            COMPOSECOMMAND="up -d --remove-orphans ${APPNAME:-}"
            COMMANDINFO="Creating ${APPNAME:-containers for all enabled services}."
            ;;
        *)
            COMPOSECOMMAND="up -d --remove-orphans"
            COMMANDINFO="Creating containers for all enabled services."
            ;;
    esac
    if run_script 'question_prompt' "${PROMPT:-}" Y "Would you like to run compose now?"; then
        info "${COMMANDINFO}"
    else
        info "Compose will not be run."
        return 1
    fi
    run_script 'install_docker'
    cd "${SCRIPTPATH}/compose/" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}/compose/\""
    run_script 'run_compose' "${COMPOSECOMMAND}"
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
}

test_docker_compose() {
    run_script 'appvars_create' WATCHTOWER
    cat "${SCRIPTPATH}/compose/.env"
    run_script 'yml_merge'
    cd "${SCRIPTPATH}/compose/" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}/compose/\""
    run_script 'run_compose' "config"
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
    run_script 'docker_compose'
}
