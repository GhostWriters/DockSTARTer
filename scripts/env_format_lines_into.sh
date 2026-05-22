#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_format_lines_into() {
	local -n _efli_out_="${1}"
	shift
	readarray -t _efli_out_ < <(run_script 'env_format_lines' "$@")
}

test_env_format_lines_into() {
	warn "CI does not test env_format_lines_into."
}
