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
                    git -C "${SCRIPTPATH}" fetch --all
                    git -C "${SCRIPTPATH}" reset --hard origin/master
                    break
                    ;;
                [Nn]* )
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
