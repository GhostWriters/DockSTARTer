#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    column
    find
)

package_manager_table() {

    local PackageManagerHeading="Package Manager"
    local NicenameHeading="Name"
    local DescriptionHeading="Description"

    local -i PackageManagerLength=${#PackageManagerHeading}
    local -i NicenameLength=${#NicenameHeading}
    local -i DescriptionLength=${#DescriptionHeading}

    local -a TableArray=()
    local -a PackageManagerList
    readarray -t PackageManagerList < <(run_script 'package_manager_list')
    for PackageManagerName in "${PackageManagerList[@]-}"; do
        local PackageManagerDescription PackageManagerNicename
        PackageManagerDescription="$(run_script 'package_manager_description' "${PackageManagerName}")"
        PackageManagerNicename="$(run_script 'package_manager_nicename' "${PackageManagerName}")"
        PackageManagerLength=$((${#PackageManagerName} > PackageManagerLength ? ${#PackageManagerName} : PackageManagerLength))
        DescriptionLength=$((${#PackageManagerDescription} > DescriptionLength ? ${#PackageManagerDescription} : DescriptionLength))
        NicenameLength=$((${#PackageManagerNicename} > NicenameLength ? ${#PackageManagerNicename} : NicenameLength))
        TableArray+=("${PackageManagerName}" "${PackageManagerNicename}" "${PackageManagerDescription}")
    done
    local PackageManagerLine DescriptionLine NicenameLine
    PackageManagerLine="$(printf %$((PackageManagerLength + 1))s '' | tr ' ' '-')"
    DescriptionLine="$(printf %$((DescriptionLength + 1))s '' | tr ' ' '-')"
    NicenameLine="$(printf %$((NicenameLength + 1))s '' | tr ' ' '-')"
    TableArray=("${PackageManagerLine}" "${NicenameLine}" "${DescriptionLine}" "${TableArray[@]}")
    printf '%s\t%s\t%s\n' "${TableArray[@]}" |
        column --table --separator $'\t' --output-separator '   ' "--table-columns=${PackageManagerHeading},${NicenameHeading},${DescriptionHeading}"
}

test_package_manager_table() {
    run_script 'package_manager_table'
}
