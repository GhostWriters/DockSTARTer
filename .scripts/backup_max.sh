#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

backup_max() {
    info "Backing up all configs."
    local BACKUP_CMD_PRE_RUN
    BACKUP_CMD_PRE_RUN=$(run_script 'env_get' BACKUP_CMD_PRE_RUN)
    eval "${BACKUP_CMD_PRE_RUN}" || error "Failed to execute BACKUP_CMD_PRE_RUN."
    run_script 'env_update'
    local DOCKERCONFDIR
    DOCKERCONFDIR=$(run_script 'env_get' DOCKERCONFDIR)
    while IFS= read -r line; do
        local APPNAME
        APPNAME=${line}
        local FILENAME
        FILENAME=${APPNAME,,}
        local BACKUP_CONFIG
        BACKUP_CONFIG=$(run_script 'env_get' "${APPNAME}_BACKUP_CONFIG")
        if [[ ${BACKUP_CONFIG} != false ]]; then
            local BACKUP_CMD_PRE_APP
            BACKUP_CMD_PRE_APP=$(run_script 'env_get' BACKUP_CMD_PRE_APP)
            eval "${BACKUP_CMD_PRE_APP}" || error "Failed to execute BACKUP_CMD_PRE_APP."
            local RUNNING
            RUNNING=$(docker inspect "${FILENAME}" 2> /dev/null | grep -Po '"Running": \Ktrue' || echo "false")
            if [[ ${RUNNING} == true ]]; then
                docker stop "${FILENAME}" > /dev/null 2>&1 || error "Unable to stop ${FILENAME}."
            fi
            run_script 'backup_create' "${FILENAME}" || return 1
            if [[ ${RUNNING} == true ]]; then
                docker start "${FILENAME}" > /dev/null 2>&1 || error "Unable to start ${FILENAME}."
            fi
            local BACKUP_CMD_POST_APP
            BACKUP_CMD_POST_APP=$(run_script 'env_get' BACKUP_CMD_POST_APP)
            eval "${BACKUP_CMD_POST_APP}" || error "Failed to execute BACKUP_CMD_POST_APP."
        else
            warning "${APPNAME}_BACKUP_CONFIG is false. ${APPNAME} will not be backed up."
        fi
    done < <(ls -A "${DOCKERCONFDIR}")
    local BACKUP_CMD_POST_RUN
    BACKUP_CMD_POST_RUN=$(run_script 'env_get' BACKUP_CMD_POST_RUN)
    eval "${BACKUP_CMD_POST_RUN}" || error "Failed to execute BACKUP_CMD_POST_RUN."
    info "All backups complete."
}

test_backup_max() {
    run_script 'backup_max'
}
