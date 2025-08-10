#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

yml_merge() {
    commands_yml_merge
}

commands_yml_merge() {
    run_script 'appvars_create_all'
    local COMPOSE_FILE=""
    notice "Adding enabled app templates to merge ${C["File"]}docker-compose.yml${NC}. Please be patient, this can take a while."
    local ENABLED_APPS
    ENABLED_APPS="$(run_script 'app_list_enabled')"
    for APPNAME in ${ENABLED_APPS-}; do
        local appname=${APPNAME,,}
        local AppName
        AppName="$(run_script 'app_nicename' "${APPNAME}")"
        local APP_FOLDER
        APP_FOLDER="$(run_script 'app_instance_folder' "${appname}")"
        if [[ -d ${APP_FOLDER}/ ]]; then
            local main_yml
            main_yml="$(run_script 'app_instance_file' "${appname}" "*.yml")"
            if [[ -f ${main_yml} ]]; then
                if run_script 'app_is_deprecated' "${APPNAME}"; then
                    warn "${C["App"]}${AppName}${NC} IS DEPRECATED!"
                    warn "Please run '${C["UserCommand"]}${APPLICATION_COMMAND} --status-disable ${AppName}${NC}' to disable it."
                fi
                local arch_yml
                arch_yml="$(run_script 'app_instance_file' "${appname}" "*.${ARCH}.yml")"
                if [[ ! -f ${arch_yml} ]]; then
                    error "${C["File"]}${arch_yml}${NC} does not exist."
                    continue
                fi
                COMPOSE_FILE="${COMPOSE_FILE}:${arch_yml}"
                local AppNetMode
                AppNetMode="$(run_script 'env_get' "${APPNAME}__NETWORK_MODE")"
                if [[ -z ${AppNetMode-} ]] || [[ ${AppNetMode} == "bridge" ]]; then
                    local hostname_yml
                    hostname_yml="$(run_script 'app_instance_file' "${appname}" "*.hostname.yml")"
                    if [[ -f ${hostname_yml} ]]; then
                        COMPOSE_FILE="${COMPOSE_FILE}:${hostname_yml}"
                    else
                        info "${C["File"]}${hostname_yml}${NC} does not exist."
                    fi
                    local ports_yml
                    ports_yml="$(run_script 'app_instance_file' "${appname}" "*.ports.yml")"
                    if [[ -f ${ports_yml} ]]; then
                        COMPOSE_FILE="${COMPOSE_FILE}:${ports_yml}"
                    else
                        info "${C["File"]}${ports_yml}${NC} does not exist."
                    fi
                elif [[ -n ${AppNetMode} ]]; then
                    local netmode_yml
                    netmode_yml="$(run_script 'app_instance_file' "${appname}" "*.netmode.yml")"
                    if [[ -f ${netmode_yml} ]]; then
                        COMPOSE_FILE="${COMPOSE_FILE}:${netmode_yml}"
                    else
                        info "${C["File"]}${netmode_yml}${NC} does not exist."
                    fi
                fi
                local MultipleStorage
                MultipleStorage="$(run_script 'env_get' DOCKER_MULTIPLE_STORAGE)"
                local -a StorageNumbers=('')
                if [[ -n ${MultipleStorage-} && ${MultipleStorage^^} =~ ON|TRUE|YES ]]; then
                    StorageNumbers+=(2 3 4)
                fi
                for Number in "${StorageNumbers[@]}"; do
                    local StorageOn
                    StorageOn="$(run_script 'env_get' "${APPNAME}__STORAGE${Number}")"
                    StorageOn="${StorageOn:-$(run_script 'env_get' "DOCKER_STORAGE${Number}")}"
                    if [[ -n ${StorageOn-} && ${StorageOn^^} =~ ON|TRUE|YES ]]; then
                        local StorageVolume
                        StorageVolume="$(run_script 'env_get' "DOCKER_VOLUME_STORAGE${Number}")"
                        if [[ -n ${StorageVolume-} ]]; then
                            local storage_yml
                            storage_yml="$(run_script 'app_instance_file' "${appname}" "*.storage${Number}.yml")"
                            if [[ -f ${storage_yml} ]]; then
                                COMPOSE_FILE="${COMPOSE_FILE}:${storage_yml}"
                            else
                                info "${F[C]}${storage_yml}${NC} does not exist."
                            fi
                        fi
                    fi
                done
                local AppDevices
                AppDevices="$(run_script 'env_get' "${APPNAME}__DEVICES")"
                if [[ -n ${AppDevices-} && ${AppDevices^^} =~ ON|TRUE|YES ]]; then
                    local devices_yml
                    devices_yml="$(run_script 'app_instance_file' "${appname}" "*.devices.yml")"
                    if [[ -f ${devices_yml} ]]; then
                        COMPOSE_FILE="${COMPOSE_FILE}:${devices_yml}"
                    else
                        info "${C["File"]}${devices_yml}${NC} does not exist."
                    fi
                fi
                COMPOSE_FILE="${COMPOSE_FILE}:${main_yml}"
                info "All configurations for ${C["App"]}${AppName}${NC} are included."
            else
                warn "${C["File"]}${main_yml}${NC} does not exist."
            fi
            run_script 'appfolders_create' "${APPNAME}"
        else
            error "${C["File"]}${APP_FOLDER}/${NC} does not exist."
        fi
    done
    if [[ -z ${COMPOSE_FILE} ]]; then
        fatal "No enabled apps found."
    fi
    info "Running compose config to create ${C["File"]}docker-compose.yml${NC} file from enabled templates."
    export COMPOSE_FILE="${COMPOSE_FILE#:}"
    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ config > ${COMPOSE_FOLDER}/docker-compose.yml" || fatal "Failed to output compose config.\nFailing command: ${C["FailingCommand"]}docker compose --project-directory ${COMPOSE_FOLDER}/ config > \"${COMPOSE_FOLDER}/docker-compose.yml\""
    info "Merging ${C["File"]}docker-compose.yml${NC} complete."
}
test_yml_merge() {
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
    run_script 'yml_merge'
    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ config" || fatal "Failed to display compose config.\nFailing command: ${C["FailingCommand"]}docker compose --project-directory ${COMPOSE_FOLDER}/ config"
    run_script 'appvars_purge' WATCHTOWER
}
