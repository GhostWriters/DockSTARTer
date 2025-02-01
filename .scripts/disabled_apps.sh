#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

disabled_apps() {
    #grep --color=never -o -P '^\s*\K([A-Z][A-Z0-9]*(__[A-Z0-9]+)?)(?=_ENABLED='"'"'?false'"'"'?$)' "${COMPOSE_ENV}"
    grep --color=never -o -P '^\s*\K[A-Z][A-Z0-9]*(?=__ENABLED\s*='"'"'?false'"'"'?$)' "${COMPOSE_ENV}" | tr '[:upper:]' '[:lower:]' | sort || true
}

test_disabled_apps() {
    # run_script 'disabled_apps'
    warn "CI does not test disabled_apps."
}
