#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

backup_med() {
    local BACKUP_CMD_PRE_RUN
    BACKUP_CMD_PRE_RUN=$(run_script 'env_get' BACKUP_CMD_PRE_RUN)
    eval "${BACKUP_CMD_PRE_RUN}" || error "Could not execute BACKUP_CMD_PRE_RUN."
    run_script 'env_update'
    run_script 'backup_create' ".env.backups"
    while IFS= read -r line; do
        local APPNAME
        APPNAME=${line/_ENABLED=true/}
        local FILENAME
        FILENAME=${APPNAME,,}
        local BACKUP_CMD_PRE_APP
        BACKUP_CMD_PRE_APP=$(run_script 'env_get' BACKUP_CMD_PRE_APP)
        eval "${BACKUP_CMD_PRE_APP}" || error "Could not execute BACKUP_CMD_PRE_APP."
        run_script 'backup_create' "${FILENAME}" || return 1
        local BACKUP_CMD_POST_APP
        BACKUP_CMD_POST_APP=$(run_script 'env_get' BACKUP_CMD_POST_APP)
        eval "${BACKUP_CMD_POST_APP}" || error "Could not execute BACKUP_CMD_POST_APP."
    done < <(grep '_ENABLED=true' < "${SCRIPTPATH}/compose/.env")
    local BACKUP_CMD_POST_RUN
    BACKUP_CMD_POST_RUN=$(run_script 'env_get' BACKUP_CMD_POST_RUN)
    eval "${BACKUP_CMD_POST_RUN}" || error "Could not execute BACKUP_CMD_POST_RUN."
    info "All backups complete."
}
