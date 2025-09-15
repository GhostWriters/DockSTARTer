#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare Title="Install Dependencies"

pm_dnf_install() {
    if use_dialog_box; then
        coproc {
            dialog_pipe "${DC["TitleSuccess"]-}Install Dependencies" "Please be patient, this can take a while.\n${DC["CommandLine"]-} ${APPLICATION_COMMAND} --install" ""
        }
        local -i DialogBox_PID=${COPROC_PID}
        local -i DialogBox_FD="${COPROC[1]}"
        pm_dnf_install_commands >&${DialogBox_FD} 2>&1
        exec {DialogBox_FD}<&-
        wait ${DialogBox_PID}
    else
        pm_dnf_install_commands
    fi
}

pm_dnf_install_commands() {
    local Command=""

    local REDIRECT='> /dev/null 2>&1 '
    if run_script 'question_prompt' Y "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
        REDIRECT='2>&1 '
    fi

    local -a Dependencies=("${PM_COMMAND_DEPS[@]}")
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

        notice "Determining packages to install."

        local IgnorePackages
        local old_IFS="${IFS}"
        IFS=','
        IgnorePackages="${PM_PACKAGE_BLACKLIST[*]}"
        IFS="${old_IFS}"

        local DepsList
        if [[ ${#Dependencies[@]} -eq 1 ]]; then
            DepsList="${Dependencies[0]}"
        else
            DepsList="$(printf '*/bin/%s ' "${Dependencies[@]}" | xargs)"
            local old_IFS="${IFS}"
            IFS=','
            DepsList="${Dependencies[*]}"
            IFS="${old_IFS}"
        fi
        Command="dnf --exclude \"${IgnorePackages}\" rq ${DepsList} --qf %{name}"
        notice "Running: ${C["RunningCommand"]}${Command}${NC}"
        Packages="$(eval "${Command}" 2> /dev/null)" ||
            fatal "Failed to find packages to install.\nFailing command: ${C["FailingCommand"]}${Command}"
        Packages="$(xargs <<< "${Packages}")"
        if [[ -z ${Packages} ]]; then
            notice "No packages found to install."
        else
            notice "Installing packages."
            Command="sudo dnf -y install ${Packages}"
            notice "Running: ${C["RunningCommand"]}${Command}${NC}"
            eval "${REDIRECT}${Command}" ||
                fatal "Failed to install dependencies from dnf.\nFailing command: ${C["FailingCommand"]}${Command}"
        fi
    fi
}

test_pm_dnf_install() {
    # run_script 'pm_dnf_repos'
    # run_script 'pm_dnf_install'
    warn "CI does not test pm_dnf_install."
}
