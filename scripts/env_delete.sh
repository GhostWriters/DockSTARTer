#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
	sed
)

env_delete() {
	local DELETE_VAR=${1-}
	local VAR_FILE=${2:-$COMPOSE_ENV}

	if [[ ${DELETE_VAR} =~ ^[A-Za-z0-9_]+: ]]; then
		# SET_VAR is in the form of "APPNAME:VARIABLE", set new file to use
		local AppName=${DELETE_VAR%%:*}
		VAR_FILE="$(run_script 'app_env_file' "${AppName}")"
		DELETE_VAR=${DELETE_VAR#"${AppName}:"}
	fi
	if [[ ! -f ${VAR_FILE} ]]; then
		# Variable file does not exist, warn and return
		warn "File '{{|File|}}${VAR_FILE}{{[-]}}' does not exist."
		return
	fi
	if ! ${GREP} -q -P "^\s*\K${DELETE_VAR}(?=\s*=)" "${VAR_FILE}"; then
		# Variable to delete does not exists, do nothing
		return
	fi

	notice "Removing variables from {{|File|}}${VAR_FILE}{{[-]}}:"
	notice "   {{|Var|}}${DELETE_VAR}{{[-]}}"
	${SED} -i "/^\s*${DELETE_VAR}\s*=/d" "${VAR_FILE}" ||
		fatal \
			"Failed to remove var '{{|Var|}}${DELETE_VAR}{{[-]}}' in '{{|File|}}${VAR_FILE}{{[-]}}'" \
			"Failing command: {{|FailingCommand|}}${SED} -i \"/^\\s*${DELETE_VAR}\\s*=/d\" \"${VAR_FILE}\""
}

test_env_delete() {
	# run_script 'env_delete'
	warn "CI does not test env_delete."
}
