#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ui_config_globals() {
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
}
