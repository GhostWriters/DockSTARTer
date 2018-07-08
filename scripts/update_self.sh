#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

update_self() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        echo
        info "Would you like to update DockSTARTer now?"
        local YN
        while true; do
            read -rp "[Yn]" YN
            case ${YN} in
                [Yy]* )
                    info "Updating DockSTARTer."
                    git -C "${SCRIPTPATH}" fetch --all > /dev/null 2>&1
                    git -C "${SCRIPTPATH}" reset --hard origin/master > /dev/null 2>&1
                    break
                    ;;
                [Nn]* )
                    info "DockSTARTer will not be updated."
                    return
                    ;;
                * )
                    error "Please answer yes or no."
                    ;;
            esac
        done
        echo
    fi
}
