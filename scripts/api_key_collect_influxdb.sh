#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

api_key_collect_influxdb() {
	# api_key_collect_influxdb [_]
	# InfluxDB v2 stores its admin token in BoltDB (not file-readable
	# safely while the container runs). The token can be set on first
	# init via DOCKER_INFLUXDB_INIT_ADMIN_TOKEN. We read whatever is
	# in compose/.env.app.influxdb (and generate one if missing on a
	# fresh install).
	local app_env="${COMPOSE_FOLDER}/.env.app.influxdb"
	if [[ ! -f ${app_env} ]]; then
		notice "${app_env} not present; skipping influxdb token collection."
		return 0
	fi

	local current=""
	run_script 'env_get_into' current "DOCKER_INFLUXDB_INIT_ADMIN_TOKEN" "${app_env}" 2> /dev/null || true

	if [[ -z ${current} ]]; then
		current=$(openssl rand -hex 32)
		run_script 'env_set' "DOCKER_INFLUXDB_INIT_ADMIN_TOKEN" "${current}" "${app_env}"
		notice "Generated and stored InfluxDB admin token (takes effect on first init only)."
	fi

	run_script 'api_key_set' "influxdb.admin_token" "${current}"
	info "InfluxDB admin token recorded."
}

test_api_key_collect_influxdb() {
	warn "CI does not test api_key_collect_influxdb (modifies persistent state)."
}
