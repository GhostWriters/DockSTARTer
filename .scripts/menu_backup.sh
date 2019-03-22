#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_backup() {
    local BACKUPOPTS
    BACKUPOPTS=()
    BACKUPOPTS+=("Settings " "Configure backup settings")
    BACKUPOPTS+=("MIN " "Backup your .env")
    BACKUPOPTS+=("MED " "Backup configs for enabled apps")
    BACKUPOPTS+=("MAX " "Backup all configs, stop/start running apps during backups")

    local BACKUPCHOICE
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        BACKUPCHOICE="Cancel"
    else
        BACKUPCHOICE=$(whiptail --fb --clear --title "DockSTARTer" --menu "What would you like to do?" 0 0 0 "${BACKUPOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi

    case "${BACKUPCHOICE}" in
        "Settings ")
            run_script 'env_update'
            run_script 'menu_app_vars' BACKUP
            ;;
        "MIN ")
            run_script 'backup_min'
            ;;
        "MED ")
            run_script 'backup_med'
            ;;
        "MAX ")
            run_script 'backup_max'
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

test_menu_backup() {
    # run_script 'menu_backup'
    warning "Travis does not test menu_backup."
}
