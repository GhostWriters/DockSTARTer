#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

api_key_collect_nzbhydra2() {
	# api_key_collect_nzbhydra2 [TIMEOUT_SECONDS]
	# NZBHydra2 uses YAML; the apiKey lives at the top level of
	# nzbhydra.yml as `apiKey: <hex>`. A full YAML parser isn't
	# warranted for a single top-level key — grep extraction is fine.
	local timeout=${1:-60}
	local app="nzbhydra2"
	local config="${DOCKER_VOLUME_CONFIG}/${app}/nzbhydra.yml"

	local elapsed=0
	while [[ ! -f ${config} && ${elapsed} -lt ${timeout} ]]; do
		sleep 2
		elapsed=$((elapsed + 2))
	done

	if [[ ! -f ${config} ]]; then
		notice "{{|App|}}${app}{{[-]}} nzbhydra.yml not present after ${timeout}s; skipping key collection."
		return 0
	fi

	local key
	key=$(awk '/^apiKey:[[:space:]]*/ {print $2; exit}' "${config}" | tr -d '"' || true)
	if [[ -z ${key} ]]; then
		warn "{{|App|}}${app}{{[-]}} nzbhydra.yml exists but apiKey was not found at top level."
		return 1
	fi

	run_script 'api_key_set' "${app}.api_key" "${key}"
	info "{{|App|}}${app}{{[-]}} API key collected."
}

test_api_key_collect_nzbhydra2() {
	warn "CI does not test api_key_collect_nzbhydra2 (requires a running container)."
}
