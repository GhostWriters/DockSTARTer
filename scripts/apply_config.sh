#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

apply_config() {
	run_script 'config_create'

	#shellcheck disable=SC2034 # (warning): LITERAL_CONFIG_FOLDER appears unused. Verify use (or export if used externally).
	LITERAL_CONFIG_FOLDER="$(run_script 'config_get' ConfigFolder)"
	#shellcheck disable=SC2034 # (warning): LITERAL_COMPOSE_FOLDER appears unused. Verify use (or export if used externally).
	LITERAL_COMPOSE_FOLDER="$(run_script 'config_get' ComposeFolder)"
	set_global_variables
	run_script 'config_theme'
	run_script 'config_package_manager'
	sort -o "${APPLICATION_INI_FILE}" "${APPLICATION_INI_FILE}"
}

test_apply_config() {
	warn "CI does not test apply_config."
}
