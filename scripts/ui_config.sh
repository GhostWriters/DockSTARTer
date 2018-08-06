#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ui_config() {
    run_script 'env_create' menu
    run_script 'menu_app_select'
    run_script 'menu_value_prompt' 'TZ'
    run_script 'menu_value_prompt' 'PUID'
    run_script 'menu_value_prompt' 'PGID'
    run_script 'menu_value_prompt' 'DOCKERCONFDIR'
    run_script 'menu_value_prompt' 'DOWNLOADSDIR'
    run_script 'menu_value_prompt' 'MEDIADIR_BOOKS'
    run_script 'menu_value_prompt' 'MEDIADIR_MOVIES'
    run_script 'menu_value_prompt' 'MEDIADIR_MUSIC'
    run_script 'menu_value_prompt' 'MEDIADIR_TV'
    run_script 'generate_yml'
    run_script 'run_compose' menu
}
