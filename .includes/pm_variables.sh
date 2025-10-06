#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -argx PM_PACKAGE_MANAGERS=(
    apk
    nala
    apt
    dnf
    pacman
    yum
    brew
)

declare -Argx PM_PACKAGE_MANAGER_COMMAND=(
    ["apk"]="apk"
    ["nala"]="nala"
    ["apt"]="apt-get"
    ["dnf"]="dnf"
    ["pacman"]="pacman"
    ["yum"]="yum"
    ["brew"]="brew"
)

declare -gx PM=''

declare -argx PM__COMMAND_DEPS=(
    "column"
    "curl"
    "dialog"
    "git"
    "grep"
    "sed"
)

declare -argx PM__PACKAGE_BLACKLIST=(
    "9base"
    "busybox-grep"
    "busybox-sed"
    "curl-minimal"
    "gitlab-shell"
)

declare -argx PM_BREW_COMMAND_DEPS=(
    "column"
    "curl"
    "dialog"
    "git"
    "ggrep"
    "gsed"
    "gstat"
    "ip"
)

pm_find_package_manager() {
    for pmname in "${PM_PACKAGE_MANAGERS[@]}"; do
        if [[ -n $(command -v "${PM_PACKAGE_MANAGER_COMMAND["${pmname}"]}") ]]; then
            PM="${pmname}"
            break
        fi
    done
    if [[ -v PM_${PM^^}_COMMAND_DEPS ]]; then
        declare -ngx PM_COMMAND_DEPS="PM_${PM^^}_COMMAND_DEPS"
    else
        declare -ngx PM_COMMAND_DEPS="PM__COMMAND_DEPS"
    fi
    if [[ -v PM_${PM^^}_COMMAND_DEPS ]]; then
        declare -ngx PM_PACKAGE_BLACKLIST="PM_${PM^^}_PACKAGE_BLACKLIST"
    else
        declare -ngx PM_PACKAGE_BLACKLIST="PM__PACKAGE_BLACKLIST"
    fi
}

pm_check_dependency() {
    local Dep=${1}
    case "${Dep}" in
        dialog)
            declare -gx DIALOG
            DIALOG="$(command -v "${Dep}")"
            [[ -n ${DIALOG} ]]
            return
            ;;
        ggrep | grep)
            declare -gx GREP
            # Get the path to either ggrep or grep
            GREP="$(command -v "ggrep" || command -v "grep")"
            if [[ -n ${GREP} ]]; then
                # Verify that the found grep command supports perl regex
                if ${GREP} --help 2> /dev/null | ${GREP} -q -- --perl-regexp; then
                    return 0
                fi
            fi
            # If we got here, the dependency is not met
            return 1
            ;;
        gsed | sed)
            declare -gx SED
            # Get the path to either gsed or sed
            SED="$(command -v "gsed" || command -v "sed")"
            if [[ -n ${SED} ]]; then
                # Verify that the found sed command is GNU sed
                if ${SED} --version &> /dev/null; then
                    return 0
                fi
            fi
            # If we got here, the dependency is not met
            return 1
            ;;
        gstat | stat)
            declare -gx STAT
            # Get the path to either gstat or stat
            STAT="$(command -v "gstat" || command -v "stat")"
            if [[ -n ${STAT} ]]; then
                # Verify that the found stat command is GNU stat
                if ${STAT} --printf="%s" /dev/null &> /dev/null; then
                    return 0
                fi
            fi
            # If we got here, the dependency is not met
            return 1
            ;;
        *)
            command -v "${Dep}" &> /dev/null
            return
            ;;
    esac
}

pm_find_package_manager
