#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

enabled_apps() {
    #grep --color=never -o -P '^\s*\K([A-Z][A-Z0-9]*(__[A-Z0-9]+)?)(?=_ENABLED='"'"'?true'"'"'?$)' "${COMPOSE_ENV}"
    grep --color=never -o -P '^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?(?=__ENABLED='"'"'?true'"'"'?)' "${COMPOSE_ENV}" | sort || true
}

test_enabled_apps() {
    # run_script 'enabled_apps'
    warn "CI does not test enabled_apps."
}
