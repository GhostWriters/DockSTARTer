#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_list_app_env_defaults() {
    local -l appname=${1-}
    run_script 'env_var_list' "$(run_script 'app_instance_file' "${appname}" ".env.app.*")"
}

test_env_list_app_env_defaults() {
    run_script 'env_list_app_env_defaults' WATCHTOWER
}
