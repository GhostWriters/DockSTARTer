#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

integrate_prowlarr() {
	# integrate_prowlarr
	# For each enabled arr (sonarr, radarr, lidarr, readarr), checks
	# whether Prowlarr already has an application entry with the
	# matching name. If not, POSTs a new entry pointing at the arr's
	# container DNS name + standard port with the collected API key.
	# Existing entries are NEVER overwritten — manual user wiring is
	# preserved by design.
	{
		printf '\n=== integrate_prowlarr @ %s ===\n' "$(date -Iseconds)"
	} >> "${INTEGRATION_LOG_FILE}" 2>&1 || true

	local prowlarr_enabled=""
	run_script 'env_get_into' prowlarr_enabled "PROWLARR__ENABLED" 2> /dev/null || true
	if ! is_true "${prowlarr_enabled}"; then
		notice "Prowlarr is not enabled; skipping integrate_prowlarr."
		return 0
	fi

	local prowlarr_key
	if ! run_script 'api_key_get_into' prowlarr_key "prowlarr.api_key"; then
		warn "Prowlarr API key not collected yet; skipping integrate_prowlarr."
		return 0
	fi

	local -A arr_apps=(
		["sonarr"]=8989
		["radarr"]=7878
		["lidarr"]=8686
		["readarr"]=8787
	)
	local -A arr_sync_categories=(
		["sonarr"]="5000,5010,5020,5030,5040,5045,5050,5080"
		["radarr"]="2000,2010,2020,2030,2040,2045,2050,2060,2070,2080"
		["lidarr"]="3000,3010,3020,3030,3040"
		["readarr"]="7000,7010,7020,7030,7040"
	)
	local -A arr_impl=(
		["sonarr"]="Sonarr"
		["radarr"]="Radarr"
		["lidarr"]="Lidarr"
		["readarr"]="Readarr"
	)

	# Get current Prowlarr applications list.
	local existing_apps
	existing_apps=$(run_script 'http_request' "GET" \
		"http://prowlarr:9696/api/v1/applications" "" \
		"X-Api-Key: ${prowlarr_key}" 2> /dev/null | sed '$d' || echo "[]")

	local arr enabled_var arr_enabled arr_key cats impl
	for arr in "${!arr_apps[@]}"; do
		enabled_var="${arr^^}__ENABLED"
		arr_enabled=""
		run_script 'env_get_into' arr_enabled "${enabled_var}" 2> /dev/null || true
		is_true "${arr_enabled}" || continue

		if ! run_script 'api_key_get_into' arr_key "${arr}.api_key"; then
			notice "${arr} key not collected yet; skipping Prowlarr wiring for it."
			continue
		fi

		# Skip if Prowlarr already has an entry with this name.
		if printf '%s' "${existing_apps}" | jq -e --arg n "${arr}" '.[] | select(.name==$n)' > /dev/null 2>&1; then
			notice "Prowlarr already has an entry for ${arr}; skipping (will not overwrite manual config)."
			continue
		fi

		cats="${arr_sync_categories[$arr]}"
		impl="${arr_impl[$arr]}"
		local cats_json
		cats_json=$(printf '%s' "${cats}" | jq -R 'split(",") | map(tonumber)')

		local body
		body=$(jq -n \
			--arg name "${arr}" \
			--arg impl "${impl}" \
			--arg cfg "${impl}Settings" \
			--arg base "http://${arr}:${arr_apps[$arr]}" \
			--arg key "${arr_key}" \
			--argjson cats "${cats_json}" \
			'{
				name: $name,
				syncLevel: "fullSync",
				implementation: $impl,
				implementationName: $impl,
				configContract: $cfg,
				fields: [
					{name: "prowlarrUrl", value: "http://prowlarr:9696"},
					{name: "baseUrl", value: $base},
					{name: "apiKey", value: $key},
					{name: "syncCategories", value: $cats}
				]
			}')

		if run_script 'http_request' "POST" \
			"http://prowlarr:9696/api/v1/applications" "${body}" \
			"X-Api-Key: ${prowlarr_key}" > /dev/null; then
			notice "Wired ${arr} into Prowlarr."
		else
			warn "Failed to wire ${arr} into Prowlarr; continuing."
		fi
	done
}

test_integrate_prowlarr() {
	warn "CI does not test integrate_prowlarr (requires a running stack)."
}
