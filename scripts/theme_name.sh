#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_name() {
	run_script 'config_get' ui.theme
}

test_theme_name() {
	run_script 'config_theme'
	run_script 'theme_name'
}
