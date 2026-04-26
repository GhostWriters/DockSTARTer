#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_run() {
	local -l action=${1-}

	run_script 'package_manager_init'
	run_script "pm__${action}"

	case "${action}" in
		install)
			pm_check_dependencies fatal "${PM_COMMAND_DEPS[@]}"
			;;
		install_docker)
			[[ -n "$(command -v docker)" ]] ||
				fatal \
					"'{{|Program|}}docker{{[-]}}' is not available. Please install '{{|Folder|}}docker{{[-]}}' and try again."
			docker compose version &> /dev/null ||
				fatal \
					"Please see {{|URL|}}https://docs.docker.com/compose/install/linux/{{[-]}} to install '{{|Folder|}}docker compose{{[-]}}'" \
					"'{{|Program|}}docker compose{{[-]}}' is not available. Please install '{{|Folder|}}docker compose{{[-]}}' and try again."
			;;
	esac
}

test_package_manager_run() {
	run_script 'package_manager_run' clean
}
