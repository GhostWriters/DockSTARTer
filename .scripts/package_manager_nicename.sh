#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_nicename() {
    local -l PackageManager=${1-}

    if ! run_script 'package_manager_is_valid' "${PackageManager}"; then
        printf '%s\n' "${PackageManager^}"
    else
        printf '%s\n' "${PM_NICENAME["${PackageManager}"]}"
    fi
}

test_package_manager_nicename() {
    warn "CI does not test package_manager_nicename."
}
