#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

set_permissions() {
    local CH_PATH
    CH_PATH=${1:-$SCRIPTPATH}
    case "${CH_PATH}" in
        # https://en.wikipedia.org/wiki/Unix_filesystem
        # Split into two in order to keep the lines shorter
        "/" | "/bin" | "/boot" | "/dev" | "/etc" | "/home" | "/lib" | "/media" | "/mnt" | "/opt" | "/proc" | "/root" | "/sbin" | "/srv" | "/sys" | "/tmp" | "/unix")
            error "Skipping permissions on ${CH_PATH} because it is a system path."
            return
            ;;
        "/usr" | "/usr/include" | "/usr/lib" | "/usr/libexec" | "/usr/local" | "/usr/share" | "/var" | "/var/log" | "/var/mail" | "/var/spool" | "/var/tmp")
            error "Skipping permissions on ${CH_PATH} because it is a system path."
            return
            ;;
        ${DETECTED_HOMEDIR}*)
            info "Setting permissions for ${CH_PATH}"
            ;;
        *)
            # TODO: Consider adding a prompt to confirm setting permissions
            warning "Setting permissions for ${CH_PATH} outside of ${DETECTED_HOMEDIR} may be unsafe."
            ;;
    esac
    local CH_PUID
    CH_PUID=${2:-$DETECTED_PUID}
    local CH_PGID
    CH_PGID=${3:-$DETECTED_PGID}
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        info "Overriding PUID and PGID for Travis."
        CH_PUID=${DETECTED_UNAME}
        CH_PGID=${DETECTED_UGROUP}
    fi
    info "Taking ownership of ${CH_PATH} for user ${CH_PUID} and group ${CH_PGID}"
    chown -R "${CH_PUID}":"${CH_PGID}" "${CH_PATH}" > /dev/null 2>&1 || true
    info "Setting file and folder permissions in ${CH_PATH}"
    chmod -R a=,a+rX,u+w,g+w "${CH_PATH}" > /dev/null 2>&1 || true
    chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "ds must be executable."
}

test_set_permissions() {
    run_script 'set_permissions'
}
