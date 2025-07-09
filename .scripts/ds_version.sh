#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ds_version() {
    echo ''
}

test_ds_version() {
    notice "DockSTARTer version: $(run_script 'ds_version')"
}
