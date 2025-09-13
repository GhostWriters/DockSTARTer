#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare Title="Install Dependencies"

pm_yum_install() {
    if use_dialog_box; then
        coproc {
            dialog_pipe "${DC["TitleSuccess"]-}Install Dependencies" "Please be patient, this can take a while.\n${DC["CommandLine"]-} ${APPLICATION_COMMAND} --install" ""
        }
        local -i DialogBox_PID=${COPROC_PID}
        local -i DialogBox_FD="${COPROC[1]}"
        pm_yum_install_commands >&${DialogBox_FD} 2>&1
        exec {DialogBox_FD}<&-
        wait ${DialogBox_PID}
    else
        pm_yum_install_commands
    fi
}

pm_yum_install_commands() {
    local -a IgnorePackages='curl-minimal'
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

        if [[ -z "$(command -v repoquery)" ]]; then
            info "Installing '${C["Program"]}repoquery${NC}'."
            Command="sudo yum -y install yum-utils"
            info "Running: ${C["RunningCommand"]}${Command}${NC}"
            eval "${REDIRECT}${Command}" ||
                fatal "Failed to install '${C["Program"]}repoquery${NC}' from yum.\nFailing command: ${C["FailingCommand"]}${Command}"
        fi
        notice "Determining packages to install."
        local DepsList
        if [[ ${#Dependencies[@]} -eq 1 ]]; then
            DepsList="${Dependencies[0]}"
        else
            local old_IFS="${IFS}"
            IFS=','
            DepsList="${Dependencies[*]}"
            IFS="${old_IFS}"
            DepsList="$(eval echo "*/bin/{${DepsList}}")"
        fi
        Command="repoquery --archlist=${ARCH} --whatprovides ${DepsList} --qf %{name}"
        info "Running: ${C["RunningCommand"]}${Command}${NC}"
        Packages="$(eval "${Command}" 2> /dev/null)" ||
            fatal "Failed to find packages to install.\nFailing command: ${C["FailingCommand"]}${Command}"
        if [[ -n ${IgnorePackages} ]]; then
            Packages="$(grep -E -v "\b(${IgnorePackages})\b" <<< "${Packages}")"
        fi
        Packages="$(sort -u <<< "${Packages}" | xargs)"
        if [[ -z ${Packages} ]]; then
            notice "No packages found to install."
        else
            notice "Installing packages."
            Command="sudo yum -y install ${Packages}"
            info "Running: ${C["RunningCommand"]}${Command}${NC}"
            eval "${REDIRECT}${Command}" ||
                fatal "Failed to install dependencies from yum.\nFailing command: ${C["FailingCommand"]}${Command}"
        fi
    fi
}

test_pm_yum_install() {
    # run_script 'pm_yum_repos'
    # run_script 'pm_yum_install'
    warn "CI does not test pm_yum_install."
}
