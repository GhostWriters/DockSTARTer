#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

disabled_apps() {
    grep --color=never -o -P '^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?(?=__ENABLED='"'"'?false'"'"'?)' "${COMPOSE_ENV}" | sort || true
}

test_disabled_apps() {
    # run_script 'disabled_apps'
    warn "CI does not test disabled_apps."
}
