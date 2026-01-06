#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    find
)

package_manager_table() {
    local -a TableArray=()
    local -a PackageManagerList
    readarray -t PackageManagerList < <(run_script 'package_manager_list')
    for PackageManagerName in "${PackageManagerList[@]-}"; do
        local PackageManagerDescription PackageManagerNicename
        PackageManagerDescription="$(run_script 'package_manager_description' "${PackageManagerName}")"
        PackageManagerNicename="$(run_script 'package_manager_nicename' "${PackageManagerName}")"
        TableArray+=("${PackageManagerName}" "${PackageManagerNicename}" "${PackageManagerDescription}")
    done
    table 3 "Package Manager" "Name" "Description" "${TableArray[@]}"
}

test_package_manager_table() {
    run_script 'package_manager_table'
}
