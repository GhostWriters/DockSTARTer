#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config() {
    local Title="Configuration Menu"
    local ConfigOpts=()
    ConfigOpts+=("Full Setup " "This goes through all menus below. Recommended for first run")
    ConfigOpts+=("Select Apps " "Select which apps to run. Previously enabled apps are remembered")
    ConfigOpts+=("Set App Variables " "Review and adjust variables for enabled apps")
    ConfigOpts+=("Set Global Variables " "Review and adjust global variables")

    local ConfigChoice
    if [[ ${CI-} == true ]]; then
        ConfigChoice="Cancel"
    else
        local -a ConfigChoiceDialog=(
            --clear
            --title "${Title}"
            --cancel-button "Exit"
            --menu "What would you like to do?" 0 0 0
            "${ConfigOpts[@]}"
        )
        ConfigChoice=$(dialog "${ConfigChoiceDialog[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
        clear
    fi

    case "${ConfigChoice}" in
        "Full Setup ")
            run_script 'env_migrate_global'
            run_script 'env_update'
            run_script 'config_global'
            run_script 'menu_app_select'
            run_script 'config_apps'
            run_script 'yml_merge'
            run_script 'docker_compose'
            ;;
        "Set Global Variables ")
            run_script 'env_migrate_global'
            run_script 'env_update'
            run_script 'config_global'
            run_script 'yml_merge'
            run_script 'docker_compose'
            ;;
        "Select Apps ")
            run_script 'env_migrate_global'
            run_script 'env_update'
            run_script 'menu_app_select'
            run_script 'yml_merge'
            run_script 'docker_compose'
            ;;
        "Set App Variables ")
            run_script 'env_migrate_global'
            run_script 'env_update'
            run_script 'config_apps'
            run_script 'yml_merge'
            run_script 'docker_compose'
            ;;
        "Cancel")
            info "Returning to Main Menu."
            return 1
            ;;
        *)
            error "Invalid Option"
            ;;
    esac
}

test_menu_config() {
    # run_script 'menu_config'
    warn "CI does not test menu_config."
}
