#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ui_config() {
    run_script 'env_create' menu
    run_script 'menu_app_select' || return 1
    run_script 'menu_value_prompt' TZ || return 1
    run_script 'menu_value_prompt' PUID || return 1
    run_script 'menu_value_prompt' PGID || return 1
    run_script 'menu_value_prompt' DOCKERCONFDIR || return 1
    run_script 'menu_value_prompt' DOCKERSHAREDDIR || return 1
    run_script 'menu_value_prompt' DOWNLOADSDIR || return 1
    run_script 'menu_value_prompt' MEDIADIR_BOOKS || return 1
    run_script 'menu_value_prompt' MEDIADIR_COMICS || return 1
    run_script 'menu_value_prompt' MEDIADIR_MOVIES || return 1
    run_script 'menu_value_prompt' MEDIADIR_MUSIC || return 1
    run_script 'menu_value_prompt' MEDIADIR_TV || return 1
    run_script 'generate_yml'
    run_script 'run_compose' menu || return 1
}
