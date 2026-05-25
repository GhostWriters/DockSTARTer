#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

api_key_collect_qbittorrent() {
	# api_key_collect_qbittorrent [TIMEOUT_SECONDS]
	# qBittorrent has no API key; it uses session auth with WebUI
	# username + password. Stores both for completeness. Actual
	# arr<->qbit traffic relies on AuthSubnetWhitelist (set up by
	# npm_app_prepare_qbittorrent in Phase 3) so passwords are not
	# required for inter-container API calls. The cleartext password
	# is NOT collected because qbit only stores a PBKDF2 hash.
	local timeout=${1:-60}
	local app="qbittorrent"
	local config="${DOCKER_VOLUME_CONFIG}/${app}/qBittorrent/config/qBittorrent.conf"

	local elapsed=0
	while [[ ! -f ${config} && ${elapsed} -lt ${timeout} ]]; do
		sleep 2
		elapsed=$((elapsed + 2))
	done

	if [[ ! -f ${config} ]]; then
		notice "{{|App|}}${app}{{[-]}} qBittorrent.conf not present after ${timeout}s; skipping credential collection."
		return 0
	fi

	local username password_hash
	username=$(awk -F'=' '/^WebUI\\Username[[:space:]]*=/ {sub(/^[[:space:]]+/,"",$2); print $2; exit}' "${config}" || true)
	password_hash=$(awk -F'=' '/^WebUI\\Password_PBKDF2[[:space:]]*=/ {sub(/^[[:space:]]+/,"",$2); print $2; exit}' "${config}" || true)

	if [[ -n ${username} ]]; then
		run_script 'api_key_set' "${app}.username" "${username}"
	fi
	if [[ -n ${password_hash} ]]; then
		run_script 'api_key_set' "${app}.password_hash" "${password_hash}"
	fi
	info "{{|App|}}${app}{{[-]}} WebUI credentials collected (username + PBKDF2 hash)."
}

test_api_key_collect_qbittorrent() {
	warn "CI does not test api_key_collect_qbittorrent (requires a running container)."
}
