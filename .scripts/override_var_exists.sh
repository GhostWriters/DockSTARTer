#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

override_var_exists() {
    # Stub.  For now, always return false
    return 1
}

test_override_var_exists() {
    warn "CI does not test override_var_exists."
}
