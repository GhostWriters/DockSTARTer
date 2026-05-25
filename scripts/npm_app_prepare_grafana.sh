#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

npm_app_prepare_grafana() {
	# npm_app_prepare_grafana Hostname
	# Sets GF_SERVER_ROOT_URL in compose/.env.app.grafana so Grafana
	# emits absolute URLs that match the public hostname. Without
	# this, OAuth callbacks and embedded links break.
	local hostname=${1-}
	local app_env="${COMPOSE_FOLDER}/.env.app.grafana"

	if [[ -z ${hostname} ]]; then
		error "npm_app_prepare_grafana requires a hostname."
		return 1
	fi
	if [[ ! -f ${app_env} ]]; then
		notice "${app_env} not present; skipping NPM-prep edits."
		return 0
	fi

	run_script 'env_set' "GF_SERVER_ROOT_URL" "https://${hostname}/" "${app_env}"
	notice "Grafana GF_SERVER_ROOT_URL set to https://${hostname}/"
}

test_npm_app_prepare_grafana() {
	warn "CI does not test npm_app_prepare_grafana (requires config file)."
}
