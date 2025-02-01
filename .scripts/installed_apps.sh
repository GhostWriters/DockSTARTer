#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

installed_apps() {
    grep --color=never -o -P '^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?(?=__ENABLED\s*=)' "${COMPOSE_ENV}" | sort || true
}

test_installed_apps() {
    # run_script 'installed_apps'
    warn "CI does not test installed_apps."
}
