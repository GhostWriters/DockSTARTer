#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

menu_backup() {
    local CONFIGOPTS
    CONFIGOPTS=()
    CONFIGOPTS+=("Settings " "Configure backup settings")
    CONFIGOPTS+=("MIN " "Backup your .env")
    CONFIGOPTS+=("MED " "Backup configs for enabled apps")
    CONFIGOPTS+=("MAX " "Backup all configs, stop/start running apps during backups")

    local CONFIGCHOICE
    CONFIGCHOICE=$(whiptail --fb --clear --title "DockSTARTer" --menu "What would you like to do?" 0 0 0 "${CONFIGOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")

    case "${CONFIGCHOICE}" in
        "Settings ")
            run_script 'menu_app_vars' BACKUP || run_script 'menu_backup'
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
