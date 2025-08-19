#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_list_app_global_defaults() {
    local -l appname=${1-}
    run_script 'env_var_list' "$(run_script 'app_instance_file' "${appname}" ".env")"
}

test_env_list_app_global_defaults() {
    run_script 'env_list_app_global_defaults' WATCHTOWER
}
