#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

reset_needs() {
	if [[ -d ${TIMESTAMPS_FOLDER:?} ]]; then
		run_script 'set_permissions' "${TIMESTAMPS_FOLDER:?}"
		rm -rf "${TIMESTAMPS_FOLDER:?}/"* &> /dev/null || true
	fi
}

test_reset_needs() {
	# run_script 'env_delete'
	warn "CI does not test reset_needs."
}
