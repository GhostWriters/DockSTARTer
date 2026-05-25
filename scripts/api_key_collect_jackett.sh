#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

api_key_collect_jackett() {
	# api_key_collect_jackett [TIMEOUT_SECONDS]
	local timeout=${1:-60}
	local app="jackett"
	local config="${DOCKER_VOLUME_CONFIG}/${app}/Jackett/ServerConfig.json"

	local elapsed=0
	while [[ ! -f ${config} && ${elapsed} -lt ${timeout} ]]; do
		sleep 2
		elapsed=$((elapsed + 2))
	done

	if [[ ! -f ${config} ]]; then
		notice "{{|App|}}${app}{{[-]}} ServerConfig.json not present after ${timeout}s; skipping key collection."
		return 0
	fi

	local key
	if ! run_script 'config_json_get_into' key ".APIKey" "${config}" || [[ -z ${key} ]]; then
		warn "{{|App|}}${app}{{[-]}} ServerConfig.json exists but .APIKey could not be read."
		return 1
	fi

	run_script 'api_key_set' "${app}.api_key" "${key}"
	info "{{|App|}}${app}{{[-]}} API key collected."
}

test_api_key_collect_jackett() {
	warn "CI does not test api_key_collect_jackett (requires a running container)."
}
