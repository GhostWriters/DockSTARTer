#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Log Functions
MKTEMP_LOG=$(mktemp -t "${APPLICATION_NAME}.log.XXXXXXXXXX") || echo -e "Failed to create temporary log file.\nFailing command: ${C["FailingCommand"]}mktemp -t \"${APPLICATION_NAME}.log.XXXXXXXXXX\""
readonly MKTEMP_LOG
echo "DockSTARTer Log" > "${MKTEMP_LOG}"
log() {
    local TOTERM=${1-}
    local MESSAGE=${2-}
    local STRIPPED_MESSAGE
    STRIPPED_MESSAGE=$(strip_ansi_colors "${MESSAGE-}")
    if [[ -n ${TOTERM} ]]; then
        if [[ -t 2 ]]; then
            # Stderr is not being redirected, output with color
            printf '%b\n' "${MESSAGE-}" >&2
        else
            # Stderr is being redirected, output without colorr
            printf '%b\n' "${STRIPPED_MESSAGE-}" >&2
        fi
    fi
    # Output the message to the log file without color
    printf '%b\n' "${STRIPPED_MESSAGE-}" >> "${MKTEMP_LOG}"
}
timestamped_log() {
    local TOTERM=${1-}
    local LogLevelTag=${2-}
    shift 2
    LogMessage=$(printf '%b' "$@")
    # Create a notice for each argument passed to the function
    local Timestamp
    Timestamp=$(date +"%F %T")
    # Create separate notices with the same timestamp for each line in a log message
    while IFS= read -r line; do
        log "${TOTERM-}" "${NC}${C["Timestamp"]}${Timestamp}${NC} ${LogLevelTag}   ${line}${NC}"
    done <<< "${LogMessage}"
}
trace() { timestamped_log "${TRACE-}" "${C["Trace"]}[TRACE ]${NC}" "$@"; }
debug() { timestamped_log "${DEBUG-}" "${C["Debug"]}[DEBUG ]${NC}" "$@"; }
info() { timestamped_log "${VERBOSE-}" "${C["Info"]}[INFO  ]${NC}" "$@"; }
notice() { timestamped_log true "${C["Notice"]}[NOTICE]${NC}" "$@"; }
warn() { timestamped_log true "${C["Warn"]}[WARN  ]${NC}" "$@"; }
error() { timestamped_log true "${C["Error"]}[ERROR ]${NC}" "$@"; }
fatal() {
    timestamped_log true "${C["Fatal"]}[FATAL ]${NC}" "$@"
    exit 1
}
