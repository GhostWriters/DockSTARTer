#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

backup_med() {
    info "Backing up configs for all enabled apps."
    local BACKUP_CMD_PRE_RUN
    BACKUP_CMD_PRE_RUN=$(run_script 'env_get' BACKUP_CMD_PRE_RUN)
    eval "${BACKUP_CMD_PRE_RUN}" || error "Failed to execute BACKUP_CMD_PRE_RUN."
    run_script 'env_update'
    run_script 'backup_create' ".compose.backups"
    while IFS= read -r line; do
        local APPNAME
        APPNAME=${line%%_ENABLED=true}
        local FILENAME
        FILENAME=${APPNAME,,}
        local BACKUP_CONFIG
        BACKUP_CONFIG=$(run_script 'env_get' "${APPNAME}_BACKUP_CONFIG")
        if [[ ${BACKUP_CONFIG} != false ]]; then
            local BACKUP_CMD_PRE_APP
            BACKUP_CMD_PRE_APP=$(run_script 'env_get' BACKUP_CMD_PRE_APP)
            eval "${BACKUP_CMD_PRE_APP}" || error "Failed to execute BACKUP_CMD_PRE_APP."
            run_script 'backup_create' "${FILENAME}" || return 1
            local BACKUP_CMD_POST_APP
            BACKUP_CMD_POST_APP=$(run_script 'env_get' BACKUP_CMD_POST_APP)
            eval "${BACKUP_CMD_POST_APP}" || error "Failed to execute BACKUP_CMD_POST_APP."
        else
            warning "${APPNAME}_BACKUP_CONFIG is false. ${APPNAME} will not be backed up."
        fi
    done < <(grep '_ENABLED=true$' < "${SCRIPTPATH}/compose/.env")
    local BACKUP_CMD_POST_RUN
    BACKUP_CMD_POST_RUN=$(run_script 'env_get' BACKUP_CMD_POST_RUN)
    eval "${BACKUP_CMD_POST_RUN}" || error "Failed to execute BACKUP_CMD_POST_RUN."
    info "All backups complete."
}

test_backup_med() {
    run_script 'backup_med'
}
