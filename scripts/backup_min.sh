#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

backup_min() {
    local BACKUP_CMD_PRE_RUN
    BACKUP_CMD_PRE_RUN=$(run_script 'env_get' BACKUP_CMD_PRE_RUN)
    eval "${BACKUP_CMD_PRE_RUN}" || error "Could not execute BACKUP_CMD_PRE_RUN."
    run_script 'env_update'
    run_script 'backup_create' ".env.backups"
    local BACKUP_CMD_POST_RUN
    BACKUP_CMD_POST_RUN=$(run_script 'env_get' BACKUP_CMD_POST_RUN)
    eval "${BACKUP_CMD_POST_RUN}" || error "Could not execute BACKUP_CMD_POST_RUN."
    info "All backups complete."
}
