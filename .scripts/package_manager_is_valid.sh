#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_is_valid() {
    local -l PackageManager=${1-}

    local Old_IFS="${IFS}"
    IFS='|'
    RegEx_PackageManagers="^(${PM_PACKAGE_MANAGERS[*]-})$"
    IFS="${Old_IFS}"

    [[ ${PackageManager} =~ ${RegEx_PackageManagers} ]]
}

test_package_manager_is_valid() {
    local ForcePass='' # Force the tests to pass even on failure if set to a non-empty value
    local -i result=0
    local -a Test=(
        apt YES
        Apt YES
        nala YES
        Nala YES
        brew YES
        xxx NO
    )
    run_unit_tests_pipe "App" "App" "${ForcePass}" < <(
        for ((i = 0; i < ${#Test[@]}; i += 2)); do
            printf '%s\n' \
                "${Test[i]}" \
                "${Test[i + 1]}" \
                "$(run_script 'package_manager_is_valid' "${Test[i]}" && echo "YES" || echo "NO")"
        done
    )
    result=$?
    return ${result}
}
