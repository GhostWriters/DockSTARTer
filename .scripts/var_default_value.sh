#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

var_default_value() {
    local VarName=${1-}
    local CleanVarName="${VarName}"

    local Default
    local VarType
    local APPNAME appname AppName
    APPNAME="$(run_script 'varname_to_appname' "${VarName}")"
    if [[ -n ${APPNAME} ]]; then
        APPNAME="${APPNAME^^}"
        appname="${APPNAME,,}"
        AppName="$(run_script 'app_nicename' "${APPNAME}")"
        if [[ ${VarName} == *":"* ]]; then
            VarType="APPENV"
            CleanVarName=${VarName#*:}
            VarName="${APPNAME}:${CleanVarName}"
        else
            VarType="APP"
        fi
    else
        VarType="GLOBAL"
    fi

    case "${VarType}" in
        APP)
            local DefaultAppVarFile
            DefaultAppVarFile="$(run_script 'app_instance_file' "${APPNAME}" ".env")"
            if [[ -f ${DefaultAppVarFile} ]] && run_script 'env_var_exists' "${CleanVarName}" "${DefaultAppVarFile}"; then
                # Variable is listed in the default file, output it and return
                run_script 'env_get_literal' "${CleanVarName}" "${DefaultAppVarFile}"
                return
            fi
            case "${CleanVarName}" in
                "${APPNAME}__CONTAINER_NAME")
                    Default="'${appname}'"
                    ;;
                "${APPNAME}__ENABLED")
                    Default="'false'"
                    ;;
                "${APPNAME}__HOSTNAME")
                    Default="'${AppName}'"
                    ;;
                "${APPNAME}__NETWORK_MODE")
                    Default="''"
                    ;;
                "${APPNAME}__RESTART")
                    Default="'unless-stopped'"
                    ;;
                "${APPNAME}__TAG")
                    Default="'latest'"
                    ;;
                "${APPNAME}__VOLUME_DOCKER_SOCKET")
                    # shellcheck disable=SC2016  # Expressions don't expand in single quotes, use double quotes for that.
                    Default='"${DOCKER_VOLUME_DOCKER_SOCKET?}"'
                    ;;
                *)
                    if [[ ${CleanVarName} =~ ^${APPNAME}__PORT_[0-9]+$ ]]; then
                        Default="'${CleanVarName#"${APPNAME}"__PORT_*}'"
                    else
                        Default="''"
                    fi
                    ;;
            esac
            ;;
        APPENV)
            local DefaultAppVarFile
            DefaultAppVarFile="$(run_script 'app_instance_file' "${APPNAME}" ".env.app.*")"
            if [[ -f ${DefaultAppVarFile} ]] && run_script 'env_var_exists' "${CleanVarName}" "${DefaultAppVarFile}"; then
                # Variable is listed in the default file, output it and return
                run_script 'env_get_literal' "${CleanVarName}" "${DefaultAppVarFile}"
                return
            fi
            Default="''"
            ;;
        GLOBAL)
            case "${CleanVarName}" in
                DOCKER_GID)
                    Default="'$(cut -d: -f3 < <(getent group docker))'"
                    ;;
                DOCKER_HOSTNAME)
                    Default="'${HOSTNAME}'"
                    ;;
                DOCKER_VOLUME_CONFIG)
                    Default="'${DETECTED_HOMEDIR}/.config/appdata'"
                    ;;
                DOCKER_VOLUME_STORAGE)
                    Default="'${DETECTED_HOMEDIR}/storage'"
                    ;;
                GLOBAL_LAN_NETWORK)
                    Default="'$(run_script 'detect_lan_network')'"
                    ;;
                PGID)
                    Default="'${DETECTED_PGID}'"
                    ;;
                PUID)
                    Default="'${DETECTED_PUID}'"
                    ;;
                TZ)
                    if [[ -f /etc/timezone ]]; then
                        Default="'$(cat /etc/timezone)'"
                    else
                        Default="'Etc/UTC'"
                    fi
                    ;;
                *)
                    if [[ -f ${COMPOSE_ENV_DEFAULT_FILE} ]] && run_script 'env_var_exists' "${CleanVarName}" "${COMPOSE_ENV_DEFAULT_FILE}"; then
                        # Variable is listed in the default file, output it and return
                        Default="$(run_script 'env_get_literal' "${CleanVarName}" "${COMPOSE_ENV_DEFAULT_FILE}")"
                    else
                        Default="''"
                    fi
                    ;;
            esac
            ;;
    esac
    echo "${Default}"
}

test_var_default_value() {
    for VarName in NONEXISTENT_GLOBAL_VAR NONEXISTENTAPP__VARNAME NONEXISTENAAPP__PORT_80 NONEXISTENTAPP__HOSTNAME WATCHTOWER__HOSTNAME DOCKER_VOLUME_STORAGE; do
        local Result
        Result="$(run_script 'var_default_value' "${VarName}")"
        echo "${VarName}=${Result}"
    done
    notice "CI does not test var_default_value"
}
