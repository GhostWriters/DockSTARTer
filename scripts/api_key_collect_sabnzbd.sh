#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

api_key_collect_sabnzbd() {
	# api_key_collect_sabnzbd [TIMEOUT_SECONDS]
	# SABnzbd stores two keys in sabnzbd.ini under [misc]:
	#   api_key = ...    (full API access)
	#   nzb_key = ...    (NZB-add-only access)
	# Both are stored; arrs typically use api_key.
	local timeout=${1:-60}
	local app="sabnzbd"
	local config="${DOCKER_VOLUME_CONFIG}/${app}/sabnzbd.ini"

	local elapsed=0
	while [[ ! -f ${config} && ${elapsed} -lt ${timeout} ]]; do
		sleep 2
		elapsed=$((elapsed + 2))
	done

	if [[ ! -f ${config} ]]; then
		notice "{{|App|}}${app}{{[-]}} config not present after ${timeout}s; skipping key collection."
		return 0
	fi

	local api_key nzb_key
	api_key=$(awk -F'[[:space:]]*=[[:space:]]*' '/^\[misc\]/{f=1;next} /^\[/{f=0} f && $1=="api_key"{print $2; exit}' "${config}" | tr -d ' "' || true)
	nzb_key=$(awk -F'[[:space:]]*=[[:space:]]*' '/^\[misc\]/{f=1;next} /^\[/{f=0} f && $1=="nzb_key"{print $2; exit}' "${config}" | tr -d ' "' || true)

	if [[ -z ${api_key} ]]; then
		warn "{{|App|}}${app}{{[-]}} sabnzbd.ini exists but api_key is empty."
		return 1
	fi

	run_script 'api_key_set' "${app}.api_key" "${api_key}"
	if [[ -n ${nzb_key} ]]; then
		run_script 'api_key_set' "${app}.nzb_key" "${nzb_key}"
	fi
	info "{{|App|}}${app}{{[-]}} keys collected."
}

test_api_key_collect_sabnzbd() {
	warn "CI does not test api_key_collect_sabnzbd (requires a running container)."
}
