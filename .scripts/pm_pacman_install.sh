#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare Title="Install Dependencies"

pm_pacman_install() {
    if use_dialog_box; then
        coproc {
            dialog_pipe "${DC["TitleSuccess"]-}${Title}" "Please be patient, this can take a while.\n${DC["CommandLine"]-} ${APPLICATION_COMMAND} --install" ""
        }
        local -i DialogBox_PID=${COPROC_PID}
        local -i DialogBox_FD="${COPROC[1]}"
        pm_pacman_install_commands >&${DialogBox_FD} 2>&1
        exec {DialogBox_FD}<&-
        wait ${DialogBox_PID}
    else
        pm_pacman_install_commands
    fi
}

pm_pacman_install_commands() {
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

        if [[ -z "$(command -v pkgfile)" ]]; then
            info "Installing '${C["Program"]}pkgfile${NC}'."
            Command="sudo pacman -Sy --noconfirm pkgfile"
            notice "Running: ${C["RunningCommand"]}${Command}${NC}"
            eval "${REDIRECT}${Command}" ||
                fatal "Failed to install '${C["Program"]}pkgfile${NC}' from pacman.\nFailing command: ${C["FailingCommand"]}${Command}"
        fi
        notice "Updating package information."
        Command='sudo pkgfile -u'
        notice "Running: ${C["RunningCommand"]}${Command}${NC}"
        eval "${REDIRECT}${Command}" ||
            fatal "Failed to get updates from pkgfile.\nFailing command: ${C["FailingCommand"]}${Command}"

        notice "Determining packages to install."

        local IgnorePackages
        local old_IFS="${IFS}"
        IFS='|'
        IgnorePackages="${PM_PACKAGE_BLACKLIST[*]}"
        IFS="${old_IFS}"

        local -a Packages
        for Dep in "${Dependencies[@]}"; do
            Command="pkgfile -b ${Dep}"
            notice "Running: ${C["RunningCommand"]}${Command}${NC}"
            Package="$(eval "${Command}" 2> /dev/null)" ||
                fatal "Failed to find packages to install.\nFailing command: ${C["FailingCommand"]}${Command}"
            Package="${Package##*/}"
            if [[ -n ${Package} && (-z ${IgnorePackages} || ! ${Package} =~ ${IgnorePackages}) ]]; then
                Packages+=("${Package}")
            fi
        done
        if [[ ${#Packages[@]} -eq 0 ]]; then
            notice "No packages found to install."
        else
            notice "Installing packages."
            readarray -t Packages < <(sort -u <<< "$(printf '%s\n' "${Packages[@]}")")
            #shellcheck disable=SC2124 # Assigning an array to a string! Assign as array, or use * instead of @ to concatenate.
            local PackagesString="${Packages[@]}"
            Command="sudo pacman -Sy --noconfirm ${PackagesString}"
            notice "Running: ${C["RunningCommand"]}${Command}${NC}"
            eval "${REDIRECT}${Command}" ||
                fatal "Failed to install dependencies from pacman.\nFailing command: ${C["FailingCommand"]}${Command}"
        fi
    fi
}

test_pm_pacman_install() {
    # run_script 'pm_pacman_repos'
    # run_script 'pm_pacman_install'
    warn "CI does not test pm_pacman_install."
}
