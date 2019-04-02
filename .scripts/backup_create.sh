#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

backup_create() {
    # http://www.pointsoftware.ch/en/howto-local-and-remote-snapshot-backup-using-rsync-with-hard-links/
    local SNAPSHOT_NAME
    SNAPSHOT_NAME="${1:-}"
    local SNAPSHOT_DST
    SNAPSHOT_DST=$(run_script 'env_get' BACKUP_CONFDIR)
    local DOCKERCONFDIR
    DOCKERCONFDIR=$(run_script 'env_get' DOCKERCONFDIR)
    local SNAPSHOT_SRC
    SNAPSHOT_SRC="${DOCKERCONFDIR}/${SNAPSHOT_NAME}"
    local BACKUP_RETENTION
    BACKUP_RETENTION=$(run_script 'env_get' BACKUP_RETENTION)
    local BACKUP_RETENTION_MAX
    BACKUP_RETENTION_MAX="${BACKUP_RETENTION%% *}"
    local PUID
    PUID=$(run_script 'env_get' PUID)
    local PGID
    PGID=$(run_script 'env_get' PGID)

    # ------------- tuning options, file locations and constants -----------
    local MIN_MIBSIZE
    MIN_MIBSIZE=$(run_script 'env_get' BACKUP_MIN_MIBSIZE)
    local OVERWRITE_LAST
    OVERWRITE_LAST=$(run_script 'env_get' BACKUP_OVERWRITE_LAST)
    local MAX_MIBSIZE
    MAX_MIBSIZE=$(run_script 'env_get' BACKUP_MAX_MIBSIZE)
    local BWLIMIT
    BWLIMIT=$(run_script 'env_get' BACKUP_BWLIMIT)
    local CHATTR
    CHATTR=$(run_script 'env_get' BACKUP_CHATTR)
    local DU
    DU=$(run_script 'env_get' BACKUP_DU)

    # ------------- initialization -----------------------------------------
    shopt -s extglob # enable extended pattern matching operators

    local OPTION
    OPTION="--stats \
    --recursive \
    --links \
    --perms \
    --times \
    --group \
    --owner \
    --devices \
    --hard-links \
    --numeric-ids \
    --delete \
    --delete-excluded \
    --bwlimit=${BWLIMIT}"
    #  --progress
    #  --size-only
    #  --stop-at
    #  --time-limit
    #  --sparse

    # ------------- check conditions ---------------------------------------
    info "Snapshot backup is created into ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.001"
    local STARTDATE
    STARTDATE=$(date +%s)

    # make sure we have a correct source folder
    if [ ! -d "${SNAPSHOT_SRC}" ]; then
        error "${SNAPSHOT_SRC} folder not found. No backup will be created."
        return
    fi

    # make sure we have a correct snapshot folder
    if [ ! -d "${SNAPSHOT_DST}" ]; then
        info "${SNAPSHOT_DST} folder not found. Attempting to create it."
        mkdir -p "${SNAPSHOT_DST}" || fatal "${SNAPSHOT_DST} folder could not be created."
        run_script 'set_permissions' "${SNAPSHOT_DST}" "${PUID}" "${PGID}"
    fi

    # ------------- remove some old backups --------------------------------
    # remove certain snapshots to achieve an exponential distribution in time of the backups (1,2,4,8,...)
    local a
    local f
    while IFS= read -r b; do
        a=$((b / 2 + 1))
        f=0 # this flag is set to 1 when we find the 1st snapshot in the range b..a
        for i in $(seq -f'%03g' "${b}" -1 "${a}"); do
            if [ -d "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}" ]; then
                if [ "${f}" -eq 0 ]; then
                    f=1
                else
                    info "Removing ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i} ..."
                    if [ "${CHATTR}" -eq 1 ]; then
                        chattr -R -i "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}" > /dev/null 2>&1 || warning "Failed to remove immutable flag from ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}"
                    fi
                    rm -rf "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}" || error "Failed to remove ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}"
                fi
            fi
        done
    done < <(echo "${BACKUP_RETENTION// /$'\n'}")

    # remove additional backups if free disk space is short
    remove_snapshot() {
        local MIN_MIBSIZE2
        MIN_MIBSIZE2=${1:-}
        local MAX_MIBSIZE2
        MAX_MIBSIZE2=${2:-}
        local d
        local FREEDISK
        for i in $(seq -f'%03g' "${BACKUP_RETENTION_MAX}" -1 001); do
            if [ -d "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}" ] || [ "${i}" -eq 1 ]; then
                if [ ! -h "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last" ] && [ -d "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}" ]; then
                    ln -s "${SNAPSHOT_NAME}.${i}" "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last" || warning "Failed to create link for ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last"
                fi
                d=0 # disk space used by snapshots and free disk space are ok
                info "Checking free disk space..."
                FREEDISK=$(df -m "${SNAPSHOT_DST}" | tail -1 | sed -e 's/  */ /g' | cut -d" " -f4 | sed -e 's/M*//g')
                info "${FREEDISK} MiB free."
                if [ "${FREEDISK}" -ge "${MIN_MIBSIZE2}" ]; then
                    info "Ok, bigger than ${MIN_MIBSIZE2} MiB."
                    if [ "${DU}" -eq 0 ]; then # avoid slow 'du'
                        break
                    else
                        info "Checking disk space used by ${SNAPSHOT_DST} ..."
                        USEDDISK=$(du -ms "${SNAPSHOT_DST}/" | cut -f1)
                        info "${USEDDISK} MiB used."
                        if [ "${USEDDISK}" -le "${MAX_MIBSIZE2}" ]; then
                            info "Ok, smaller than ${MAX_MIBSIZE2} MiB."
                            break
                        else
                            d=2 # disk space used by snapshots is too big
                        fi
                    fi
                else
                    d=1 # free disk space is too small
                fi
                if [ ${d} -ne 0 ]; then # we need to remove snapshots
                    if [ "${i}" -ne 1 ]; then
                        info "Removing ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i} ..."
                        if [ "${CHATTR}" -eq 1 ]; then
                            chattr -R -i "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}" > /dev/null 2>&1 || warning "Failed to remove immutable flag from ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}"
                        fi
                        rm -rf "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}" || error "Failed to remove ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}"
                        if [ -h "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last" ]; then
                            rm -f "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last" || error "Failed to remove ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last"
                        fi
                    else # all snapshots except snapshot.001 are removed
                        if [ ${d} -eq 1 ]; then # snapshot.001 causes that free space is too small
                            if [ "${OVERWRITE_LAST}" -eq 1 ]; then # last chance: remove snapshot.001 and retry once
                                OVERWRITE_LAST=0
                                warning "Warning, free disk space will be smaller than ${MIN_MIBSIZE} MiB."
                                info "OVERWRITE_LAST enabled. Removing ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.001 ..."
                                rm -rf "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.001" || error "Failed to remove ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.001"
                                if [ -h "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last" ]; then
                                    rm -f "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last" || error "Failed to remove ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last"
                                fi
                            else
                                for j in ${LNKDST//--link-dest=/}; do
                                    if [ -d "${j}" ] && [ "${CHATTR}" -eq 1 ] && [ "$(lsattr -d "${j}" | cut -b5)" != "i" ]; then
                                        chattr -R +i "${j}" > /dev/null 2>&1 || warning "Failed to make ${j} backup immutable. Backup files may be overwritten by future backups." # undo unprotection that was needed to use hardlinks
                                    fi
                                    if [ ! -h "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last" ]; then
                                        ln -s "${SNAPSHOT_NAME}.${j}" "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last" || warning "Failed to create link for ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last"
                                    fi
                                done
                                fatal "Sorry, free disk space will be smaller than ${MIN_MIBSIZE} MiB. Exiting..."
                            fi
                        elif [ ${d} -eq 2 ]; then # snapshot.001 causes that disk space used by snapshots is too big
                            warning "Warning, disk space used by ${SNAPSHOT_DST} will be bigger than ${MAX_MIBSIZE} MiB. Continuing anyway..."
                        fi
                    fi
                fi
            fi
        done
    }

    # perform an estimation of required disk space for the new backup
    local LNKDST
    local OOVERWRITE_LAST
    local LOG
    while :; do # this loop is executed a 2nd time if OVERWRITE_LAST was ==1 and snapshot.001 got removed
        OOVERWRITE_LAST="${OVERWRITE_LAST}"
        info "Testing needed free disk space ..."
        mkdir -p "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.test-free-disk-space" || fatal "Failed to create ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.test-free-disk-space"
        chmod -R 775 "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.test-free-disk-space" || fatal "Failed to set permissions on ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.test-free-disk-space"
        LOG="$(mktemp)"
        LNKDST=$(find "${SNAPSHOT_DST}/" -maxdepth 2 -type d -name "${SNAPSHOT_NAME}.001" -printf " --link-dest=%p")
        for i in ${LNKDST//--link-dest=/}; do
            if [ -d "${i}" ] && [ "${CHATTR}" -eq 1 ] && [ "$(lsattr -d "${i}" | cut -b5)" == "i" ]; then
                chattr -R -i "${i}" > /dev/null 2>&1 || warning "Failed to remove immutable flag from ${i}" # unprotect last snapshots to use hardlinks
            fi
        done
        eval rsync \
            --dry-run \
            "${OPTION}" \
            "${LNKDST}" \
            "${SNAPSHOT_SRC}" "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.test-free-disk-space" >> "${LOG}" || fatal "Snapshot space estimation failed."

        i=$(($(tail -100 "${LOG}" | grep 'Total transferred file size:' | cut -d " " -f5 | sed -e 's/\,//g') / 1048576))
        info "${i} MiB needed."
        rm -rf "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.test-free-disk-space" || fatal "Failed to remove ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.test-free-disk-space"
        rm -rf "${LOG}" || warning "Temporary backup log file could not be removed."
        remove_snapshot $((MIN_MIBSIZE + i)) $((MAX_MIBSIZE - i))
        if [ "${OOVERWRITE_LAST}" == "${OVERWRITE_LAST}" ]; then # no need to retry
            break
        fi
    done

    # ------------- create the snapshot backup -----------------------------
    # perform the filesystem backup using rsync and hard-links to the latest snapshot
    # Note:
    #   -rsync behaves like cp --remove-destination by default, so the destination
    #    is unlinked first.  If it were not so, this would copy over the other
    #    snapshot(s) too!
    #   -use --link-dest to hard-link when possible with previous snapshot,
    #    timestamps, permissions and ownerships are preserved
    info "Creating folder ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.000 ..."
    mkdir -p "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.000"
    chmod 775 "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.000"
    info "Creating backup of ${SNAPSHOT_NAME} into ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.000"
    if [ -n "${LNKDST}" ]; then
        info "Hardlinked with${LNKDST//--link-dest=/} ..."
    else
        info "Not hardlinked ..."
    fi
    eval rsync \
        -vv \
        "${OPTION}" \
        "${LNKDST}" \
        "${SNAPSHOT_SRC}" "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.000" > /dev/null 2>&1 || fatal "Snapshot failed."
    for i in ${LNKDST//--link-dest=/}; do
        if [ -d "${i}" ] && [ "${CHATTR}" -eq 1 ] && [ "$(lsattr -d "${i}" | cut -b5)" != "i" ]; then
            chattr -R +i "${i}" > /dev/null 2>&1 || warning "Failed to make ${i} backup immutable. Backup files may be overwritten by future backups." # undo unprotection that was needed to use hardlinks
        fi
    done

    # ------------- finish and clean up ------------------------------------
    # protect the backup against modification with chattr +immutable
    if [ "${CHATTR}" -eq 1 ]; then
        info "Setting recursively immutable flag of ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.000 ..."
        chattr -R +i "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.000" > /dev/null 2>&1 || warning "Failed to make ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.000 backup immutable. Backup files may be overwritten by future backups."
    fi

    # rotate the backups
    if [ -d "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${BACKUP_RETENTION_MAX}" ]; then # remove snapshot.${BACKUP_RETENTION_MAX}
        info "Removing ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${BACKUP_RETENTION_MAX} ..."
        if [ "${CHATTR}" -eq 1 ]; then
            chattr -R -i "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${BACKUP_RETENTION_MAX}" > /dev/null 2>&1 || warning "Failed to remove immutable flag from ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${BACKUP_RETENTION_MAX}"
        fi
        rm -rf "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${BACKUP_RETENTION_MAX}" || error "Failed to create ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${BACKUP_RETENTION_MAX}"
    fi
    if [ -h "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last" ]; then
        rm -f "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last" || error "Failed to create ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last"
    fi
    local j
    for i in $(seq -f'%03g' "$((BACKUP_RETENTION_MAX - 1))" -1 000); do
        if [ -d "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}" ]; then
            j=$((${i##+(0)} + 1))
            j=$(printf "%.3d" "${j}")
            info "Renaming ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i} into ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${j} ..."
            if [ "${CHATTR}" -eq 1 ]; then
                chattr -i "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}" > /dev/null 2>&1 || warning "Failed to remove immutable flag from ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}"
            fi
            mv "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${i}" "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${j}"
            if [ "${CHATTR}" -eq 1 ]; then
                chattr +i "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${j}" > /dev/null 2>&1 || warning "Failed to make ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.${j} backup immutable. Backup files may be overwritten by future backups."
            fi
            if [ ! -h "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last" ]; then
                ln -s "${SNAPSHOT_NAME}.${j}" "${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last" || warning "Failed to create link for ${SNAPSHOT_DST}/${SNAPSHOT_NAME}.last"
            fi
        fi
    done

    # remove additional backups if free disk space is short
    OVERWRITE_LAST=0 # next call of remove_snapshot() will not remove snapshot.001
    remove_snapshot "${MIN_MIBSIZE}" "${MAX_MIBSIZE}"
    run_script 'set_permissions' "${SNAPSHOT_DST}" "${PUID}" "${PGID}"
    info "Snapshot backup successfully done in $(($(date +%s) - STARTDATE)) sec."
}

test_backup_create() {
    run_script 'env_update'
    run_script 'backup_create' ".compose.backups"
}
