#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

api_key_collect_sonarr() {
	# api_key_collect_sonarr [TIMEOUT_SECONDS]
	# Reads <ApiKey> from sonarr's config.xml and stores it in
	# api_keys.toml under [sonarr].api_key. If the file is missing
	# (app hasn't started for the first time yet), polls for up to
	# TIMEOUT_SECONDS (default 60) before giving up with a notice.
	local timeout=${1:-60}
	local app="sonarr"
	local config="${DOCKER_VOLUME_CONFIG}/${app}/config.xml"

	local elapsed=0
	while [[ ! -f ${config} && ${elapsed} -lt ${timeout} ]]; do
		sleep 2
		elapsed=$((elapsed + 2))
	done

	if [[ ! -f ${config} ]]; then
		notice "{{|App|}}${app}{{[-]}} config not present after ${timeout}s; skipping key collection."
		return 0
	fi

	local key
	if ! run_script 'config_xml_get_into' key "//Config/ApiKey" "${config}" || [[ -z ${key} ]]; then
		warn "{{|App|}}${app}{{[-]}} config.xml exists but <ApiKey> could not be read."
		return 1
	fi

	run_script 'api_key_set' "${app}.api_key" "${key}"
	info "{{|App|}}${app}{{[-]}} API key collected."
}

test_api_key_collect_sonarr() {
	warn "CI does not test api_key_collect_sonarr (requires a running container)."
}
