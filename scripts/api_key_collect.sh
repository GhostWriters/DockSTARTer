#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

api_key_collect() {
	# api_key_collect [--force]
	# Walks the list of known apps and invokes api_key_collect_<app>
	# for each enabled one whose collector script exists. Per-app
	# polling is internal to each collector. After all collectors
	# complete, regenerates the derived ${COMPOSE_FOLDER}/.env.app.keys
	# file from api_keys.toml so compose templates can interpolate.
	local force="false"
	if [[ ${1-} == "--force" ]]; then
		force="true"
	fi

	# Apps that have a collector AND for which it makes sense to scrape.
	# Phase 1: arrs. Phase 2: download clients + aggregators.
	# Phase 3+: NPM, jellyfin, db layer.
	local -a candidates=(
		"sonarr" "radarr" "lidarr" "prowlarr"
		"sabnzbd" "jackett" "nzbhydra2" "qbittorrent"
		"mariadb" "influxdb"
	)

	local -i collected=0 skipped=0 failed=0
	local app collector enabled_var enabled
	for app in "${candidates[@]}"; do
		collector="api_key_collect_${app}"
		if [[ ! -f ${SCRIPTPATH}/scripts/${collector}.sh ]]; then
			continue
		fi

		enabled_var="${app^^}__ENABLED"
		enabled=""
		run_script 'env_get_into' enabled "${enabled_var}" 2> /dev/null || true
		if ! is_true "${enabled}"; then
			skipped=$((skipped + 1))
			continue
		fi

		if [[ ${force} == "true" ]]; then
			# Drop existing value so the collector re-scrapes.
			run_script 'api_key_set' "${app}.api_key" "" 2> /dev/null || true
		fi

		if run_script "${collector}"; then
			collected=$((collected + 1))
		else
			failed=$((failed + 1))
			warn "Key collection for {{|App|}}${app}{{[-]}} failed."
		fi
	done

	notice "API key collection complete: ${collected} ok, ${skipped} disabled, ${failed} failed."

	if [[ ${collected} -gt 0 ]]; then
		run_script 'api_keys_to_env' || warn "Failed to regenerate ${API_KEYS_ENV_FILE_NAME}."
	fi
}

test_api_key_collect() {
	warn "CI does not test api_key_collect (orchestrator over per-app collectors)."
}
