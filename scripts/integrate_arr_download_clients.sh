#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

integrate_arr_download_clients() {
	# integrate_arr_download_clients
	# For each enabled arr × enabled download client (sabnzbd + qbittorrent),
	# GET the arr's /api/v3/downloadclient first; if no entry with the
	# matching name exists, POST a new one. Existing entries are skipped.
	{
		printf '\n=== integrate_arr_download_clients @ %s ===\n' "$(date -Iseconds)"
	} >> "${INTEGRATION_LOG_FILE}" 2>&1 || true

	local -A arrs=(
		["sonarr"]=8989
		["radarr"]=7878
		["lidarr"]=8686
	)

	local arr arr_port arr_key arr_enabled
	for arr in "${!arrs[@]}"; do
		arr_port="${arrs[$arr]}"
		arr_enabled=""
		run_script 'env_get_into' arr_enabled "${arr^^}__ENABLED" 2> /dev/null || true
		is_true "${arr_enabled}" || continue
		if ! run_script 'api_key_get_into' arr_key "${arr}.api_key"; then
			notice "${arr} key not collected yet; skipping its download-client wiring."
			continue
		fi

		local existing
		existing=$(run_script 'http_request' "GET" \
			"http://${arr}:${arr_port}/api/v3/downloadclient" "" \
			"X-Api-Key: ${arr_key}" 2> /dev/null | sed '$d' || echo "[]")

		_wire_sabnzbd_into "${arr}" "${arr_port}" "${arr_key}" "${existing}"
		_wire_qbittorrent_into "${arr}" "${arr_port}" "${arr_key}" "${existing}"
	done
}

_wire_sabnzbd_into() {
	local arr=$1 arr_port=$2 arr_key=$3 existing=$4
	local sab_enabled=""
	run_script 'env_get_into' sab_enabled "SABNZBD__ENABLED" 2> /dev/null || true
	is_true "${sab_enabled}" || return 0
	local sab_key
	run_script 'api_key_get_into' sab_key "sabnzbd.api_key" || return 0

	if printf '%s' "${existing}" | jq -e '.[] | select(.name=="SABnzbd")' > /dev/null 2>&1; then
		notice "${arr} already has SABnzbd configured; skipping."
		return 0
	fi

	local body
	body=$(jq -n \
		--arg key "${sab_key}" \
		'{
			enable: true,
			protocol: "usenet",
			priority: 1,
			name: "SABnzbd",
			implementation: "Sabnzbd",
			configContract: "SabnzbdSettings",
			fields: [
				{name: "host", value: "sabnzbd"},
				{name: "port", value: 8080},
				{name: "apiKey", value: $key},
				{name: "useSsl", value: false}
			]
		}')

	if run_script 'http_request' "POST" \
		"http://${arr}:${arr_port}/api/v3/downloadclient" "${body}" \
		"X-Api-Key: ${arr_key}" > /dev/null; then
		notice "Wired SABnzbd into ${arr}."
	fi
}

_wire_qbittorrent_into() {
	local arr=$1 arr_port=$2 arr_key=$3 existing=$4
	local qbit_enabled=""
	run_script 'env_get_into' qbit_enabled "QBITTORRENT__ENABLED" 2> /dev/null || true
	is_true "${qbit_enabled}" || return 0

	if printf '%s' "${existing}" | jq -e '.[] | select(.name=="qBittorrent")' > /dev/null 2>&1; then
		notice "${arr} already has qBittorrent configured; skipping."
		return 0
	fi

	# Username/password not required: AuthSubnetWhitelist (set up by
	# npm_app_prepare_qbittorrent) grants the docker network unauthenticated
	# API access.
	local body
	body=$(jq -n \
		'{
			enable: true,
			protocol: "torrent",
			priority: 1,
			name: "qBittorrent",
			implementation: "QBittorrent",
			configContract: "QBittorrentSettings",
			fields: [
				{name: "host", value: "qbittorrent"},
				{name: "port", value: 8080},
				{name: "username", value: ""},
				{name: "password", value: ""},
				{name: "useSsl", value: false}
			]
		}')

	if run_script 'http_request' "POST" \
		"http://${arr}:${arr_port}/api/v3/downloadclient" "${body}" \
		"X-Api-Key: ${arr_key}" > /dev/null; then
		notice "Wired qBittorrent into ${arr} (auth bypass via AuthSubnetWhitelist)."
	fi
}

test_integrate_arr_download_clients() {
	warn "CI does not test integrate_arr_download_clients (requires a running stack)."
}
