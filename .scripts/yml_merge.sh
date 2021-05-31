#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

yml_merge() {
    run_script 'env_update'
    run_script 'appvars_create_all'
    info "Merging docker-compose.yml file."
    local MKTEMP_RUN_YQ
    MKTEMP_RUN_YQ=$(mktemp) || fatal "Failed to create temporary run compose script.\nFailing command: ${F[C]}mktemp"
    info "Downloading run compose script."
    curl -fsSL https://raw.githubusercontent.com/linuxserver/docker-yq/master/run-yq.sh -o "${MKTEMP_RUN_YQ}" > /dev/null 2>&1 || fatal "Failed to get run yq script.\nFailing command: ${F[C]}curl -fsSL https://raw.githubusercontent.com/linuxserver/docker-yq/master/run-yq.sh -o \"${MKTEMP_RUN_YQ}\""
    docker pull ghcr.io/linuxserver/yq:latest || fatal "Failed to pull latest yq image.\nFailing command: ${F[C]}docker pull ghcr.io/linuxserver/yq:latest"
    local MKTEMP_YML_MERGE
    MKTEMP_YML_MERGE=$(mktemp) || fatal "Failed to create temporary yml merge script.\nFailing command: ${F[C]}mktemp"
    echo "#!/usr/bin/env bash" > "${MKTEMP_YML_MERGE}"
    {
        echo "export YQ_OPTIONS=\"${YQ_OPTIONS:-} -v ${SCRIPTPATH}:${SCRIPTPATH}\""
        echo "sh \"${MKTEMP_RUN_YQ}\" -y -s 'reduce .[] as \$item ({}; . * \$item) | del(.version)' "\\
        echo "\"${SCRIPTPATH}/compose/.reqs/r1.yml\" \\"
        echo "\"${SCRIPTPATH}/compose/.reqs/r2.yml\" \\"
    } >> "${MKTEMP_YML_MERGE}"
    info "Required files included."
    notice "Adding compose configurations for enabled apps. Please be patient, this can take a while."
    while IFS= read -r line; do
        local APPNAME=${line%%_ENABLED=true}
        local FILENAME=${APPNAME,,}
        if [[ -d ${SCRIPTPATH}/compose/.apps/${FILENAME}/ ]]; then
            if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml ]]; then
                local APPDEPRECATED
                APPDEPRECATED=$(grep --color=never -Po "\scom\.dockstarter\.appinfo\.deprecated: \K.*" "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.labels.yml" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo "false")
                if [[ ${APPDEPRECATED} == "true" ]]; then
                    warn "${APPNAME} IS DEPRECATED!"
                    warn "Please edit ${SCRIPTPATH}/compose/.env and set ${APPNAME}_ENABLED to false."
                    continue
                fi
                if [[ ! -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml ]]; then
                    error "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml does not exist."
                    continue
                fi
                echo "\"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml\" \\" >> "${MKTEMP_YML_MERGE}"
                local APPNETMODE
                APPNETMODE=$(run_script 'env_get' "${APPNAME}_NETWORK_MODE")
                if [[ -z ${APPNETMODE} ]] || [[ ${APPNETMODE} == "bridge" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.hostname.yml ]]; then
                        echo "\"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.hostname.yml\" \\" >> "${MKTEMP_YML_MERGE}"
                    else
                        info "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.hostname.yml does not exist."
                    fi
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml ]]; then
                        echo "\"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml\" \\" >> "${MKTEMP_YML_MERGE}"
                    else
                        info "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml does not exist."
                    fi
                elif [[ -n ${APPNETMODE} ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml ]]; then
                        echo "\"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml\" \\" >> "${MKTEMP_YML_MERGE}"
                    else
                        info "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml does not exist."
                    fi
                fi
                echo "\"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml\" \\" >> "${MKTEMP_YML_MERGE}"
                info "All configurations for ${APPNAME} are included."
            else
                warn "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml does not exist."
            fi
        else
            error "${SCRIPTPATH}/compose/.apps/${FILENAME}/ does not exist."
        fi
    done < <(grep '_ENABLED=true$' < "${SCRIPTPATH}/compose/.env")
    echo "> \"${SCRIPTPATH}/compose/docker-compose.yml\"" >> "${MKTEMP_YML_MERGE}"
    info "Running compiled script to merge docker-compose.yml file."
    bash "${MKTEMP_YML_MERGE}" > /dev/null 2>&1 || fatal "Failed to run yml merge script.\nFailing command: ${F[C]}bash \"${MKTEMP_YML_MERGE}\""
    rm -f "${MKTEMP_YML_MERGE}" || warn "Failed to remove temporary yml merge script."
    info "Merging docker-compose.yml complete."
}

test_yml_merge() {
    run_script 'update_system'
    run_script 'appvars_create' WATCHTOWER
    cat "${SCRIPTPATH}/compose/.env"
    run_script 'yml_merge'
    cd "${SCRIPTPATH}/compose/" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}/compose/\""
    local MKTEMP_RUN_COMPOSE
    MKTEMP_RUN_COMPOSE=$(mktemp) || fatal "Failed to create temporary run compose script.\nFailing command: ${F[C]}mktemp"
    info "Downloading run compose script."
    curl -fsSL https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o "${MKTEMP_RUN_COMPOSE}" > /dev/null 2>&1 || fatal "Failed to get run yq script.\nFailing command: ${F[C]}curl -fsSL https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o \"${MKTEMP_RUN_COMPOSE}\""
    docker pull ghcr.io/linuxserver/docker-compose:latest || fatal "Failed to pull latest docker-compose image.\nFailing command: ${F[C]}docker pull ghcr.io/linuxserver/docker-compose:latest"
    eval sh "${MKTEMP_RUN_COMPOSE}" config || fatal "Failed to validate ${SCRIPTPATH}/compose/docker-compose.yml file.\nFailing command: ${F[C]}eval sh \"${MKTEMP_RUN_COMPOSE}\" config"
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
    run_script 'appvars_purge' WATCHTOWER
}
