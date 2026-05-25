#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

api_keys_to_env() {
	# api_keys_to_env
	# Regenerates ${COMPOSE_FOLDER}/${API_KEYS_ENV_FILE_NAME} from
	# the canonical ${API_KEYS_TOML_FILE}, flattening sections to
	# uppercase prefixes (e.g. [sonarr].api_key -> SONARR_API_KEY).
	# This is the file docker-compose interpolates when integration
	# templates reference ${SONARR_API_KEY?} etc.
	if [[ ! -f ${API_KEYS_TOML_FILE} ]]; then
		notice "${API_KEYS_TOML_FILE} does not exist; nothing to regenerate."
		return 0
	fi

	if [[ ! -d ${COMPOSE_FOLDER} ]]; then
		warn "COMPOSE_FOLDER does not exist; skipping ${API_KEYS_ENV_FILE_NAME} regeneration."
		return 0
	fi

	local OutFile="${COMPOSE_FOLDER}/${API_KEYS_ENV_FILE_NAME}"
	local TempFile
	TempFile=$(mktemp -t "${APPLICATION_NAME}.api_keys_to_env.XXXXXXXXXX")

	{
		printf '###\n### DockSTARTer integration secrets\n###\n'
		printf '### Auto-generated from %s\n' "${API_KEYS_TOML_FILE}"
		printf '### DO NOT EDIT \xe2\x80\x94 changes will be overwritten.\n###\n\n'
	} > "${TempFile}"

	local current_section="" line key value section flat
	while IFS= read -r line || [[ -n ${line} ]]; do
		# Section header
		if [[ ${line} =~ ^\[([^\]]+)\]$ ]]; then
			current_section="${BASH_REMATCH[1]}"
			continue
		fi
		# Skip blanks and comments
		if [[ -z ${line// } || ${line} =~ ^[[:space:]]*# ]]; then
			continue
		fi
		# key = "value" or key = value
		if [[ ${line} =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
			key="${BASH_REMATCH[1]}"
			value="${BASH_REMATCH[2]}"
			# Strip surrounding single or double quotes
			value="${value%\"}"
			value="${value#\"}"
			value="${value%\'}"
			value="${value#\'}"
			# Skip nested-table headers (e.g. [prowlarr.applications]) and pure-meta keys
			if [[ ${key} == "bootstrap_in_progress" ]]; then
				continue
			fi
			section="${current_section//./_}"
			flat="${section^^}_${key^^}"
			printf "%s='%s'\n" "${flat}" "${value}" >> "${TempFile}"
		fi
	done < "${API_KEYS_TOML_FILE}"

	mv "${TempFile}" "${OutFile}"
	chmod 600 "${OutFile}" || true
}

test_api_keys_to_env() {
	warn "CI does not test api_keys_to_env (depends on persistent state file)."
}
