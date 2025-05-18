#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_list_app_global_defaults() {
    local APPNAME=${1-}
    local appname=${APPNAME,,}
    run_script 'env_var_list' "$(run_script 'instance_file' "${appname}" ".global.env")"
}

test_env_list_app_global_defaults() {
    run_script 'env_list_app_global_defaults' WATCHTOWER
}
