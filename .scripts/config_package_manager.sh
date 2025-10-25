#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_package_manager() {
    local -l PackageManager
    if [[ $# -gt 0 ]]; then
        PackageManager=${1}
    fi

    if [[ ! -f ${APPLICATION_INI_FILE} ]]; then
        run_script 'config_create'
    fi

    if ! run_script 'env_var_exists' PackageManager "${APPLICATION_INI_FILE}"; then
        local DefaultIniFile="${DEFAULTS_FOLDER}/${APPLICATION_INI_NAME}"
        local DefaultPackageManager
        DefaultPackageManager="$(run_script 'config_get' PackageManager "${DefaultIniFile}")"
        notice \
            "Setting config option in ${C["File"]}${APPLICATION_INI_FILE}${NC}:" \
            "   ${C["Var"]}PackageManager='${DefaultPackageManager}'${NC}"
        run_script 'config_set' PackageManager "${DefaultPackageManager}"
    fi

    if [[ -n ${PackageManager+x} ]]; then
        if [[ -n ${PackageManager} ]]; then
            if ! run_script 'package_manager_is_valid' "${PackageManager}"; then
                error \
                    "Selected package manager '${C["UserCommand"]}${PackageManager}${NC}' unknown.\n" \
                    "\n" \
                    "Known package managers are:\n" \
                    "\n" \
                    "$(run_script 'package_manager_table')\n"
                return 1
            fi
            run_script 'config_set' PackageManager "${PackageManager}"
            notice "Package manager set to '${C["UserCommand"]}${PackageManager}${NC}'."
        else
            run_script 'config_set' PackageManager "${PackageManager}"
            notice "Package manager set to autodetect."
        fi

        if [[ -n ${PackageManager} ]] && ! run_script 'package_manager_exists' "${PackageManager}"; then
            warn \
                "Selected package manager '${C["UserCommand"]}${PackageManager}${NC}' not detected.\n" \
                "\n" \
                "Detected package managers are:\n" \
                "\n" \
                "$(run_script 'package_manager_existing_table')\n"
        fi
    fi

}

test_config_package_manager() {
    warn "CI does not test config_package_manager."
}
