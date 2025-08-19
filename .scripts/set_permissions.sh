#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

set_permissions() {
    local CH_PATH=${1:-$SCRIPTPATH}
    case "${CH_PATH}" in
        # https://en.wikipedia.org/wiki/Unix_filesystem
        # Split into two in order to keep the lines shorter
        "/" | "/bin" | "/boot" | "/dev" | "/etc" | "/home" | "/lib" | "/media" | "/mnt" | "/opt" | "/proc" | "/root" | "/sbin" | "/srv" | "/sys" | "/tmp" | "/unix")
            error "Skipping permissions on '${C["Folder"]}${CH_PATH}${NC}' because it is a system path."
            return
            ;;
        "/usr" | "/usr/include" | "/usr/lib" | "/usr/libexec" | "/usr/local" | "/usr/share" | "/var" | "/var/log" | "/var/mail" | "/var/spool" | "/var/tmp")
            error "Skipping permissions on '${C["Folder"]}${CH_PATH}${NC}' because it is a system path."
            return
            ;;
        ${DETECTED_HOMEDIR}*)
            info "Setting permissions for '${C["Folder"]}${CH_PATH}${NC}'"
            ;;
        *)
            # TODO: Consider adding a prompt to confirm setting permissions
            warn "Setting permissions for ${CH_PATH} outside of ${DETECTED_HOMEDIR} may be unsafe."
            ;;
    esac
    local CH_PUID=${2:-$DETECTED_PUID}
    local CH_PGID=${3:-$DETECTED_PGID}
    if [[ ${CH_PUID} -ne 0 ]] && [[ ${CH_PGID} -ne 0 ]]; then
        info "Taking ownership of '${C["Folder"]}${CH_PATH}${NC}' for user '${C["User"]}${CH_PUID}${NC}' and group '${C["User"]}${CH_PGID}${NC}'"
        sudo chown -R "${CH_PUID}":"${CH_PGID}" "${CH_PATH}" > /dev/null 2>&1 || true
        info "Setting file and folder permissions in '${C["Folder"]}${CH_PATH}${NC}'"
        sudo chmod -R a=,a+rX,u+w,g+w "${CH_PATH}" > /dev/null 2>&1 || true
    fi
    info "Setting executable permission on '${C["File"]}${SCRIPTNAME}${NC}'"
    sudo chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "'${C["UserCommand"]}${APPLICATION_COMMAND}${NC}' must be executable.\nFailing command: ${C["FailingCommand"]}sudo chmod +x \"${SCRIPTNAME}\""
}

test_set_permissions() {
    run_script 'set_permissions'
}
