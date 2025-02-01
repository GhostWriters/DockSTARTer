#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_migrate_all() {
    run_script 'appvars_migrate_enabled_lines'
    local INSTALLED_APPS
    INSTALLED_APPS=$(run_script 'installed_apps')
    for APPNAME in ${INSTALLED_APPS-}; do
        run_script 'appvars_migrate' "${APPNAME}"
    done
}

test_migrate_all() {
    # run_script 'appvars_migrate_all'
    warn "CI does not test appvars_migrate_all."
}
