#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare Title="Install Dependencies"

pm_nala_install() {
    if use_dialog_box; then
        coproc {
            dialog_pipe "${DC["TitleSuccess"]-}Install Dependencies" "Please be patient, this can take a while.\n${DC["CommandLine"]-} ${APPLICATION_COMMAND} --install" ""
        }
        local -i DialogBox_PID=${COPROC_PID}
        local -i DialogBox_FD="${COPROC[1]}"
        pm_nala_install_commands >&${DialogBox_FD} 2>&1
        exec {DialogBox_FD}<&-
        wait ${DialogBox_PID}
    else
        pm_nala_install_commands
    fi
}

pm_nala_install_commands() {
    local Command=""

    local REDIRECT='> /dev/null 2>&1 '
    if run_script 'question_prompt' Y "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
        REDIRECT='2>&1 '
    fi

    local -a Dependencies=("${COMMAND_DEPS[@]}")
    if [[ ${FORCE-} != true ]]; then
        for index in "${!Dependencies[@]}"; do
            if [[ -n $(command -v "${Dependencies[index]}") ]]; then
                unset 'Dependencies[index]'
            fi
        done
        Dependencies=("${Dependencies[@]}")
    fi
    if [[ ${#Dependencies[@]} -eq 0 ]]; then
        notice "All dependencies have already been installed."
    else
        notice "Installing dependencies. Please be patient, this can take a while."

        if [[ -z "$(command -v apt-file)" ]]; then
            info "Installing '${C["Program"]}apt-file${NC}'."
            Command="sudo nala install -y apt-file"
            notice "Running: ${C["RunningCommand"]}${Command}${NC}"
            eval "${REDIRECT}${Command}" ||
                fatal "Failed to install '${C["Program"]}apt-file${NC}' from apt.\nFailing command: ${C["FailingCommand"]}${Command}"
        fi
        notice "Updating package information."
        Command='sudo apt-file update'
        notice "Running: ${C["RunningCommand"]}${Command}${NC}"
        eval "${REDIRECT}${Command}" ||
            fatal "Failed to get updates from apt.\nFailing command: ${C["FailingCommand"]}${Command}"

        notice "Determining packages to install."

        local IgnorePackages
        local old_IFS="${IFS}"
        IFS='|'
        IgnorePackages="${PM_PACKAGE_BLACKLIST[*]}"
        IFS="${old_IFS}"

        local old_IFS="${IFS}"
        IFS='|'
        local DepsRegex="${Dependencies[*]}"
        IFS="${old_IFS}"

        Command="apt-file search --regexp '/bin/(?:${DepsRegex})$'"
        notice "Running: ${C["RunningCommand"]}${Command}${NC}"
        Packages="$(eval "2> /dev/null ${Command}")" ||
            fatal "Failed to find packages to install.\nFailing command: ${C["FailingCommand"]}${Command}"
        Packages="$(cut -d : -f 1 <<< "${Packages}")"
        if [[ -n ${IgnorePackages} ]]; then
            Packages="$(grep -E -v "\b(${IgnorePackages})\b" <<< "${Packages}")"
        fi
        Packages="$(sort -u <<< "${Packages}" | xargs)"
        if [[ -z ${Packages} ]]; then
            notice "No packages found to install."
        else
            notice "Installing packages."
            Command="sudo nala install -y ${Packages}"
            notice "Running: ${C["RunningCommand"]}${Command}${NC}"
            eval "${REDIRECT}${Command}" ||
                fatal "Failed to install dependencies from nala.\nFailing command: ${C["FailingCommand"]}${Command}"
        fi
    fi
}
test_pm_nala_install() {
    #run_script 'pm_nala_repos'
    #run_script 'pm_nala_install'
    warn "CI does not test pm_nala_install."
}
