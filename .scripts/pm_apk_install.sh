#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare Title="Install Dependencies"

pm_apk_install() {
    if use_dialog_box; then
        coproc {
            dialog_pipe "${DC["TitleSuccess"]-}${Title}" "Please be patient, this can take a while.\n${DC["CommandLine"]-} ${APPLICATION_COMMAND} --install" ""
        }
        local -i DialogBox_PID=${COPROC_PID}
        local -i DialogBox_FD="${COPROC[1]}"
        pm_apk_install_commands >&${DialogBox_FD} 2>&1
        exec {DialogBox_FD}<&-
        wait ${DialogBox_PID}
    else
        pm_apk_install_commands
    fi
}

pm_apk_install_commands() {
    local Command=""

    local REDIRECT='> /dev/null 2>&1 '
    if [[ -n ${VERBOSE-} ]]; then
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
        IFS='|'
        IgnorePackages="${PM_PACKAGE_BLACKLIST[*]}"
        IFS="${old_IFS}"

        local -a Packages
        local DepsSearch
        DepsSearch="$(printf 'cmd:%s ' "${Dependencies[@]}" | xargs)"
        Command="apk search -xqa ${DepsSearch}"
        notice "Running: ${C["RunningCommand"]}${Command}${NC}"
        local Packages
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
            Command="sudo apk add ${Packages}"
            notice "Running: ${C["RunningCommand"]}${Command}${NC}"
            eval "${REDIRECT}${Command}" ||
                fatal "Failed to install dependencies from apk.\nFailing command: ${C["FailingCommand"]}${Command}"
        fi
    fi
}

test_pm_apk_install() {
    # run_script 'pm_apk_repos'
    # run_script 'pm_apk_install'
    warn "CI does not test pm_apk_install."
}
