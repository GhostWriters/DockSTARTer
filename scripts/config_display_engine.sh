#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_display_engine() {
	local -l DisplayEngine=${1-dialog}

	if [[ ! -f ${APPLICATION_TOML_FILE} ]]; then
		run_script 'config_create'
	fi

	case "${DisplayEngine}" in
		dialog | whiptail)
			run_script 'config_set' ui.display_engine "${DisplayEngine}"
			run_script 'config_theme'
			notice "Display engine set to '{{|UserCommand|}}${DisplayEngine}{{[-]}}'."
			return 0
			;;
	esac

	error \
		"Selected display engine '{{|UserCommand|}}${DisplayEngine}{{[-]}}' unknown." \
		"" \
		"Known display engines are:" \
		"\tdialog" \
		"\twhiptail"
	return 1
}

test_config_display_engine() {
	warn "CI does not test config_display_engine."
}
