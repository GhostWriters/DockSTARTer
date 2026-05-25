#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

api_key_collect_mariadb() {
	# api_key_collect_mariadb [_]
	# MariaDB stores no password on disk — MYSQL_ROOT_PASSWORD is set
	# at container init via env. Record whatever value is in
	# compose/.env.app.mariadb so the dashboard/integration layer can
	# reference it. If unset, generate one and write it back; this
	# only takes effect on a fresh install (re-init would require
	# `ALTER USER` against a running instance, which is out of scope).
	local app_env="${COMPOSE_FOLDER}/.env.app.mariadb"
	if [[ ! -f ${app_env} ]]; then
		notice "${app_env} not present; skipping mariadb password collection."
		return 0
	fi

	local current=""
	run_script 'env_get_into' current "MYSQL_ROOT_PASSWORD" "${app_env}" 2> /dev/null || true

	if [[ -z ${current} ]]; then
		current=$(openssl rand -base64 24 | tr -d '\n=' | tr '+/' '-_')
		run_script 'env_set' "MYSQL_ROOT_PASSWORD" "${current}" "${app_env}"
		notice "Generated and stored MariaDB root password (takes effect on first init only)."
	fi

	run_script 'api_key_set' "mariadb.root_password" "${current}"
	info "MariaDB root password recorded."
}

test_api_key_collect_mariadb() {
	warn "CI does not test api_key_collect_mariadb (modifies persistent state)."
}
