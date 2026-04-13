#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	sed
)

env_copy() {
	local FROM_VAR=${1-}
	local TO_VAR=${2-}
	local FROM_VAR_FILE=${3:-$COMPOSE_ENV}
	local TO_VAR_FILE=${4:-$FROM_VAR_FILE}

	if [[ ! -f ${FROM_VAR_FILE} ]]; then
		# Source file does not exist, warn and return
		warn "File '{{|File|}}${FROM_VAR_FILE}{{[-]}}' does not exist."
		return
	fi
	if [[ ${FROM_VAR_FILE} == "${TO_VAR_FILE}" && ${FROM_VAR} == "${TO_VAR}" ]]; then
		# Trying to move to the same name in the same file, do nothing
		return
	fi

	local NEW_VAR_LINE
	NEW_VAR_LINE="$(${SED} -n "s/^\s*${FROM_VAR}\s*=/${TO_VAR}=/gp" "${FROM_VAR_FILE}" | tail -1)"
	if [[ -z ${NEW_VAR_LINE} ]]; then
		# Source variable does not exist, do nothing
		return
	fi
	if [[ ! -f ${TO_VAR_FILE} ]]; then
		# Destination file does not exist, create it
		notice "Creating '{{|File|}}${TO_VAR_FILE}{{[-]}}'"
		touchfile "${TO_VAR_FILE}"
	fi
	if run_script 'env_var_exists' "${TO_VAR}" "${TO_VAR_FILE}"; then
		# Destination variable exists, do nothing
		return
	fi

	if [[ ${FROM_VAR_FILE} == "${TO_VAR_FILE}" ]]; then
		notice "Copying variable in {{|File|}}${FROM_VAR_FILE}{{[-]}}:"
		notice "   {{|Var|}}${FROM_VAR}{{[-]}} to {{|Var|}}${TO_VAR}{{[-]}}"
	else
		notice "Copying variable:"
		notice "   {{|Var|}}${FROM_VAR}{{[-]}} [{{|File|}}${FROM_VAR_FILE}{{[-]}}] to"
		notice "   {{|Var|}}${TO_VAR}{{[-]}} [{{|File|}}${TO_VAR_FILE}{{[-]}}]"
	fi
	printf '\n%s\n' "${NEW_VAR_LINE}" >> "${TO_VAR_FILE}" ||
		fatal \
			"Failed to add '{{|Var|}}${NEW_VAR_LINE}{{[-]}}' in '{{|File|}}${TO_VAR_FILE}{{[-]}}'" \
			"Failing command: {{|FailingCommand|}}printf '\n%s\n' \"${NEW_VAR_LINE}\" >> \"${TO_VAR_FILE}\""
}

test_env_copy() {
	warn "CI does not test env_copy."
}
