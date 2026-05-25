#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

npm_app_prepare_transmission() {
	# npm_app_prepare_transmission Hostname
	# Adds Hostname to transmission's rpc-host-whitelist (settings.json)
	# and ensures rpc-whitelist-enabled is false (we use host-whitelist).
	local hostname=${1-}
	local config="${DOCKER_VOLUME_CONFIG}/transmission/settings.json"

	if [[ -z ${hostname} ]]; then
		error "npm_app_prepare_transmission requires a hostname."
		return 1
	fi
	if [[ ! -f ${config} ]]; then
		notice "transmission settings.json not present; skipping NPM-prep edits."
		return 0
	fi

	local existing
	existing=$(run_script 'config_json_get' '."rpc-host-whitelist"' "${config}" || true)

	if [[ ",${existing}," != *",${hostname},"* ]]; then
		local merged="${hostname}"
		if [[ -n ${existing} ]]; then
			merged="${existing%,}, ${hostname}"
		fi
		run_script 'config_json_set' '."rpc-host-whitelist"' "${merged}" "${config}"
	fi

	run_script 'config_json_set' '=raw:."rpc-host-whitelist-enabled"' "true" "${config}"

	notice "transmission rpc-host-whitelist updated to include {{|Url|}}${hostname}{{[-]}}."
}

test_npm_app_prepare_transmission() {
	warn "CI does not test npm_app_prepare_transmission (requires config file)."
}
