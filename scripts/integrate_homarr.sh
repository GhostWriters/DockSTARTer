#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

integrate_homarr() {
	# integrate_homarr
	# Generates a Homarr config (configs/default.json) that registers
	# every enabled app as a tile with the appropriate API integration
	# wired up. Skips if the file already exists (won't overwrite user
	# customisation).
	{
		printf '\n=== integrate_homarr @ %s ===\n' "$(date -Iseconds)"
	} >> "${INTEGRATION_LOG_FILE}" 2>&1 || true

	local homarr_enabled=""
	run_script 'env_get_into' homarr_enabled "HOMARR__ENABLED" 2> /dev/null || true
	is_true "${homarr_enabled}" || {
		notice "Homarr is not enabled; skipping integrate_homarr."
		return 0
	}

	local config_dir="${DOCKER_VOLUME_CONFIG}/homarr/configs"
	local config_file="${config_dir}/default.json"
	if [[ -f ${config_file} ]]; then
		notice "Homarr config already exists; skipping (won't overwrite user customisation)."
		return 0
	fi
	mkdir -p "${config_dir}" || return 0

	local domain=""
	run_script 'env_get_into' domain "GLOBAL_DOMAIN" 2> /dev/null || true

	# Build apps array dynamically from enabled apps.
	local -a tiles=()
	local -A integration_kinds=(
		["sonarr"]="sonarr"
		["radarr"]="radarr"
		["lidarr"]="lidarr"
		["prowlarr"]="prowlarr"
		["sabnzbd"]="sabnzbd"
		["qbittorrent"]="qBittorrent"
		["jellyfin"]="jellyfin"
		["jackett"]="jackett"
		["nzbhydra2"]="nzbHydra2"
	)

	local app slug enabled key href
	for slug in "${!integration_kinds[@]}"; do
		enabled=""
		run_script 'env_get_into' enabled "${slug^^}__ENABLED" 2> /dev/null || true
		is_true "${enabled}" || continue
		key=""
		run_script 'api_key_get_into' key "${slug}.api_key" 2> /dev/null || true
		if [[ -n ${domain} ]]; then
			href="https://${slug}.${domain}"
		else
			href="http://${slug}:8080"
		fi
		local tile
		tile=$(jq -n \
			--arg id "${slug}" \
			--arg name "${slug}" \
			--arg url "${href}" \
			--arg kind "${integration_kinds[$slug]}" \
			--arg apikey "${key}" \
			'{
				id: $id,
				name: $name,
				url: $url,
				appearance: {iconUrl: ("https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/" + $id + ".png")},
				network: {enabledStatusChecker: true},
				integration: ($kind | if . == "" then null else {type: ., properties: [{field: "apiKey", value: $apikey}]} end)
			}')
		tiles+=("${tile}")
	done

	local apps_json
	apps_json=$(printf '%s\n' "${tiles[@]}" | jq -s '.')

	jq -n --argjson apps "${apps_json}" \
		'{
			schemaVersion: 1,
			configProperties: {name: "DockSTARTer"},
			apps: $apps,
			widgets: [],
			categories: [],
			wrappers: [{id: "default", position: 0}],
			settings: {common: {defaultConfig: "default"}, customization: {layout: {enabledLeftSidebar: true, enabledRightSidebar: true}}}
		}' > "${config_file}"

	chmod 600 "${config_file}" || true
	notice "Wrote Homarr config (${#tiles[@]} tiles) to ${config_file}."
}

test_integrate_homarr() {
	warn "CI does not test integrate_homarr (requires a running stack)."
}
