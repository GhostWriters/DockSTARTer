#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ui_controller() {
    run_menu 'application_selector'
    run_menu 'timezone_set'
    run_menu 'user_group_set'
    run_menu 'config_folder_set'
    run_menu 'download_folder_set'
    run_menu 'media_folders_set'
    run_script 'generate_yml'
    run_script 'run_compose'
}
