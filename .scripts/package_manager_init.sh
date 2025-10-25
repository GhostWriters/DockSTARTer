#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_init() {
    if [[ -v PM ]]; then
        # Package manager already initialized, nothing to do
        return
    fi
    run_script 'config_package_manager'

    declare -lgx PM

    local NoticeType="info"
    local PreferredPackageManager
    PreferredPackageManager="$(run_script 'config_get' PackageManager)"
    if [[ -n ${PreferredPackageManager} ]]; then
        if ! run_script 'package_manager_is_valid' "${PreferredPackageManager}"; then
            NoticeType="warn"
            ${NoticeType} \
                "Selected package manager '${C["UserCommand"]}${PreferredPackageManager}${NC}' unknown.\n" \
                "\n" \
                "Known package managers are:\n" \
                "\n" \
                "$(run_script 'package_manager_table')\n" \
                " "
        elif ! run_script 'package_manager_exists' "${PreferredPackageManager}"; then
            NoticeType="warn"
            ${NoticeType} \
                "Selected package manager '${C["UserCommand"]}${PreferredPackageManager}${NC}' not detected.\n" \
                "\n" \
                "Detected package managers are:\n" \
                "\n" \
                "$(run_script 'package_manager_existing_table')\n" \
                " "
        else
            PM="${PreferredPackageManager}"
        fi
    fi
    if [[ -z ${PM-} ]]; then
        for pmname in "${PM_PACKAGE_MANAGERS[@]}"; do
            if run_script 'package_manager_exists' "${pmname}"; then
                PM="${pmname}"
                break
            fi
        done
    fi

    if [[ -z ${PM-} ]]; then
        fatal \
            "Unable to detect a compatible package manager." \
            "\n" \
            "Known package managers are:\n" \
            "\n" \
            "$(run_script 'package_manager_table')\n" \
            " "
    fi

    local NoticeText
    if [[ ${PM} == "${PreferredPackageManager}" ]]; then
        NoticeText="Using selected package manager '${C["UserCommand"]}${PM}${NC}'."
    else
        NoticeText="Using detected package manager '${C["UserCommand"]}${PM}${NC}'."
    fi
    ${NoticeType} "${NoticeText}"

    # Set the global variables to use for the selected package manager
    if [[ -v PM_${PM^^}_COMMAND_DEPS ]]; then
        declare -ngx PM_COMMAND_DEPS="PM_${PM^^}_COMMAND_DEPS"
    else
        declare -ngx PM_COMMAND_DEPS="PM__COMMAND_DEPS"
    fi
    if [[ -v PM_${PM^^}_DEP_PACKAGE ]]; then
        declare -ngx PM_DEP_PACKAGE="PM_${PM^^}_DEP_PACKAGE"
    else
        declare -ngx PM_DEP_PACKAGE="PM__DEP_PACKAGE"
    fi
    if [[ -v PM_${PM^^}_PACKAGE_BLACKLIST ]]; then
        declare -ngx PM_PACKAGE_BLACKLIST="PM_${PM^^}_PACKAGE_BLACKLIST"
    else
        declare -ngx PM_PACKAGE_BLACKLIST="PM__PACKAGE_BLACKLIST"
    fi
}

test_package_manager_init() {
    run_script 'package_manager_init'
}
