#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare Title="Install Dependencies"

pm_brew_install() {
    if use_dialog_box; then
        coproc {
            dialog_pipe "${DC["TitleSuccess"]-}${Title}" "Please be patient, this can take a while.\n${DC["CommandLine"]-} ${APPLICATION_COMMAND} --install" ""
        }
        local -i DialogBox_PID=${COPROC_PID}
        local -i DialogBox_FD="${COPROC[1]}"
        pm_brew_install_commands >&${DialogBox_FD} 2>&1
        exec {DialogBox_FD}<&-
        wait ${DialogBox_PID}
    else
        pm_brew_install_commands
    fi
}

pm_brew_install_commands() {
    local Command=""

    local REDIRECT='> /dev/null 2>&1 '
    if [[ -n ${VERBOSE-} ]]; then
        REDIRECT='2>&1 '
    fi

    local -a Dependencies=("${PM_COMMAND_DEPS[@]}")
    if [[ ${FORCE-} != true ]]; then
        for index in "${!Dependencies[@]}"; do
            if pm_check_dependency "${Dependencies[index]}"; then
                unset 'Dependencies[index]'
            fi
        done
        Dependencies=("${Dependencies[@]}")
    fi
    if [[ ${#Dependencies[@]} -eq 0 ]]; then
        notice "All dependencies have already been installed."
    else
        notice "Installing dependencies. Please be patient, this can take a while."

        notice "Determining packages to install."
        local Packages
        Packages="$(detect_packages "${Dependencies[@]}" | xargs)"

        if [[ -z ${Packages} ]]; then
            notice "No packages found to install."
        else
            notice "Installing packages."
            Command="brew install ${Packages}"
            notice "Running: ${C["RunningCommand"]}${Command}${NC}"
            eval "${REDIRECT}${Command}" ||
                fatal "Failed to install dependencies from brew.\nFailing command: ${C["FailingCommand"]}${Command}"
        fi
    fi
}

detect_packages() {
    local -a Dependencies=("$@")

    Old_IFS="${IFS}"
    IFS='|'
    RegEx_Package_Blacklist="(${PM_PACKAGE_BLACKLIST[*]-})"
    IFS="${Old_IFS}"

    local DepsSearch
    DepsSearch="$(printf '%s ' "${Dependencies[@]}" | xargs)"

    local Command="brew which-formula ${DepsSearch}"
    notice "Running: ${C["RunningCommand"]}${Command}${NC}"
    eval "${Command}" 2> /dev/null | while IFS= read -r line; do
        if [[ ! ${line} =~ ^${RegEx_Package_Blacklist}$ ]]; then
            echo "${line}"
        fi
    done | sort -u
}

test_pm_brew_install() {
    warn "CI does not test pm_brew_install."
}
