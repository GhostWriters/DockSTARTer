#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_name() {
	get_toml_val_string "${APPLICATION_TOML_FILE}" "ui.theme"
}

test_theme_name() {
	run_script 'config_theme'
	run_script 'theme_name'
}
