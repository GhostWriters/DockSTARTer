#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_migrate() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    warn "appvars_migrate ${APPNAME} not implemented yet."
}

test_appvars_migrate() {
    # run_script 'appvars_migrate'
    warn "CI does not test appvars_migrate."
}
