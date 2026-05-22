#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

apply_config() {
	if [[ ! -f ${APPLICATION_TOML_FILE} ]]; then
		run_script 'config_create'
		return
	fi

	#shellcheck disable=SC2034 # (warning): LITERAL_CONFIG_FOLDER appears unused. Verify use (or export if used externally).
	run_script 'config_get_into' LITERAL_CONFIG_FOLDER paths.config_folder || true
	#shellcheck disable=SC2034 # (warning): LITERAL_COMPOSE_FOLDER appears unused. Verify use (or export if used externally).
	run_script 'config_get_into' LITERAL_COMPOSE_FOLDER paths.compose_folder || true
	set_global_variables
	run_script 'config_theme'
	run_script 'config_package_manager'
}

test_apply_config() {
	warn "CI does not test apply_config."
}
