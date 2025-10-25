#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -argx PM_PACKAGE_MANAGERS=(
    nala
    apt
    apk
    pacman
    dnf
    yum
    brew
    none
)

declare -Argx PM_PACKAGE_MANAGER_COMMAND=(
    ["apk"]="apk"
    ["nala"]="nala"
    ["apt"]="apt-get"
    ["dnf"]="dnf"
    ["pacman"]="pacman"
    ["yum"]="yum"
    ["brew"]="brew"
    ["port"]="port"
    ["none"]="bash"
)

declare -Argx PM_NICENAME=(
    ["apk"]="APK"
    ["nala"]="Nala"
    ["apt"]="APT"
    ["dnf"]="DNF"
    ["pacman"]="Pacman"
    ["yum"]="YUM"
    ["brew"]="Homebrew"
    ["port"]="MacPorts"
    ["none"]="None"
)

declare -Argx PM_DESCRIPTION=(
    ["apk"]="Alpine Package Keeper (Alpine Linux)"
    ["nala"]="Nala alternative to Apt (Debian, Ubuntu)"
    ["apt"]="Advanced Package Tool (Debian, Ubuntu)"
    ["dnf"]="Dandified YUM (Fedora, CentOS)"
    ["yum"]="Yellowdog Updater, Modified (Fedora, CentOS)"
    ["pacman"]="Package Manager (Arch Linux)"
    ["brew"]="Homebrew (macOS)"
    ["port"]="MacPorts (macOS)"
    ["none"]="No package manager"
)

declare -argx PM__COMMAND_DEPS=(
    "column"
    "curl"
    "dialog"
    "find"
    "git"
    "grep"
    "sed"
    "stat"
)

declare -Argx PM__DEP_PACKAGE=()

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
    "gfind"
    "git"
    "ggrep"
    "gsed"
    "gstat"
    "ip"
)

declare -argx PM_PORT_COMMAND_DEPS=(
    "column"
    "curl"
    "dialog"
    "gfind"
    "git"
    "ggrep"
    "gsed"
    "gstat"
    "ip"
)

declare -argx PM_NONE_COMMAND_DEPS=(
    "column"
    "curl"
    "dialog"
    "gfind"
    "git"
    "ggrep"
    "gsed"
    "gstat"
    "ip"
)

declare -Argx PM_PORT_DEP_PACKAGE=(
    ["dialog"]="dialog"
    ["find"]="findutils"
    ["gsed"]="gnu-sed"
    ["ip"]="iproute2mac"
)

pm_check_dependency() {
    local Dep=${1}
    case "${Dep}" in
        dialog)
            declare -gx DIALOG
            DIALOG="$(command -v "${Dep}")"
            [[ -n ${DIALOG} ]]
            return
            ;;
        gfind | find)
            declare -gx FIND
            # Get the path to either gfind or find
            FIND="$(command -v "gfind" || command -v "find")"
            if [[ -n ${FIND} ]]; then
                # Verify that the found grep command is GNU find
                if ${FIND} . -maxdepth 0 -printf "" &> /dev/null; then
                    return 0
                fi
            fi
            # If we got here, the dependency is not met
            return 1
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

pm_check_dependencies() {
    local -l NoticeType=${1}
    shift
    local Dependencies=("$@")

    for index in "${!Dependencies[@]}"; do
        if pm_check_dependency "${Dependencies[index]}"; then
            unset 'Dependencies[index]'
        fi
    done
    if [[ ${#Dependencies[@]} -gt 0 ]]; then
        case "${NoticeType}" in
            notice | warn | error | fatal)
                ${NoticeType} "$(
                    printf \
                        "Dependency '${C["Program"]-}%s${NC-}' is not installed.\n" \
                        "${Dependencies[@]}"
                )\n" \
                    "Not all dependencies are installed.\n" \
                    "Either install them manually, or run '${C["UserCommand"]-}${APPLICATION_COMMAND} -i${NC-}' to install dependencies."
                ;;
        esac
        return 1
    fi
    return 0
}
