#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_name() {
	run_script 'env_get' Theme "${APPLICATION_INI_FILE}"
}

test_theme_name() {
	run_script 'config_theme'
	run_script 'theme_name'
}
