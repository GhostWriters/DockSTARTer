#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_package_manager() {
	local -l PackageManager
	if [[ $# -gt 0 ]]; then
		PackageManager=${1}
	fi

	if [[ ! -f ${APPLICATION_TOML_FILE} ]]; then
		run_script 'config_create'
	fi

	if [[ -n ${PackageManager+x} ]]; then
		if [[ -n ${PackageManager} ]]; then
			if ! run_script 'package_manager_is_valid' "${PackageManager}"; then
				error \
					"Selected package manager '{{|UserCommand|}}${PackageManager}{{[-]}}' unknown." \
					"" \
					"Known package managers are:" \
					"" \
					"$(run_script 'package_manager_table')"
				return 1
			fi
			set_toml_val_string "${APPLICATION_TOML_FILE}" "pm.package_manager" "${PackageManager}"
			notice "Package manager set to '{{|UserCommand|}}${PackageManager}{{[-]}}'."
		else
			set_toml_val_string "${APPLICATION_TOML_FILE}" "pm.package_manager" ""
			notice "Package manager set to autodetect."
		fi

		if [[ -n ${PackageManager} ]] && ! run_script 'package_manager_exists' "${PackageManager}"; then
			warn \
				"Selected package manager '{{|UserCommand|}}${PackageManager}{{[-]}}' not detected." \
				"" \
				"Detected package managers are:" \
				"" \
				"$(run_script 'package_manager_existing_table')"
		fi
	fi

}

test_config_package_manager() {
	warn "CI does not test config_package_manager."
}
