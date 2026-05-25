#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

integrate_npm() {
	# integrate_npm
	# Top-level NPM orchestrator. Sequence:
	#   1. Bail if NPM is not enabled or GLOBAL_DOMAIN is empty.
	#   2. Bootstrap NPM (rotate default creds) if needed.
	#   3. Ensure the dockstarter-admin access-list exists.
	#   4. Create npm.<domain> proxy host gated by that access-list.
	#   5. For each enabled non-excluded app:
	#      - run per-app prepare script if one exists
	#      - look up the app's main HTTP port
	#      - create the proxy host
	#      - request HTTP-01 cert (with DNS preflight)
	#
	# Best-effort: a failure on one app logs to integration.log and
	# continues to the next.
	{
		printf '\n=== integrate_npm @ %s ===\n' "$(date -Iseconds)"
	} >> "${INTEGRATION_LOG_FILE}" 2>&1 || true

	local npm_enabled=""
	run_script 'env_get_into' npm_enabled "NGINXPROXYMANAGER__ENABLED" 2> /dev/null || true
	if ! is_true "${npm_enabled}"; then
		notice "NGINXPROXYMANAGER__ENABLED is not true; skipping integrate_npm."
		return 0
	fi

	local domain=""
	run_script 'env_get_into' domain "GLOBAL_DOMAIN" 2> /dev/null || true
	if [[ -z ${domain} ]]; then
		warn "GLOBAL_DOMAIN is empty; skipping integrate_npm."
		return 0
	fi

	run_script 'npm_bootstrap' || {
		warn "NPM bootstrap failed; aborting integrate_npm."
		return 1
	}

	local admin_acl_id
	if ! admin_acl_id=$(run_script 'npm_access_list_default'); then
		warn "Could not create/find NPM admin access-list; admin UI host will be unguarded."
		admin_acl_id=0
	fi

	# Self-proxy: npm.<domain> -> nginxproxymanager:81 with access-list gate.
	run_script 'npm_host_create' "nginxproxymanager" "81" "npm.${domain}" "" "${admin_acl_id}" || \
		warn "Failed to create NPM self-proxy."
	run_script 'npm_cert_request_http01' "npm.${domain}" || true

	# Discover enabled apps from the compose .env, skipping excluded ones.
	local -a excluded=(
		"GLUETUN" "FLARESOLVERR" "NGINXPROXYMANAGER"
	)

	local var enabled_value name slug port app_var advanced
	while IFS='=' read -r var _; do
		[[ ${var} =~ ^([A-Z][A-Z0-9_]*)__ENABLED$ ]] || continue
		name="${BASH_REMATCH[1]}"

		# Skip excluded
		local skip=false
		local x
		for x in "${excluded[@]}"; do
			if [[ ${name} == "${x}" ]]; then skip=true; break; fi
		done
		[[ ${skip} == true ]] && continue

		enabled_value=""
		run_script 'env_get_into' enabled_value "${var}" 2> /dev/null || true
		is_true "${enabled_value}" || continue

		slug="${name,,}"
		port=$(_integrate_npm_pick_port "${name}")
		if [[ -z ${port} ]]; then
			warn "Skipping ${slug}: no HTTP port found."
			continue
		fi

		# Per-app prepare hooks (config edits before proxying).
		if [[ -f ${SCRIPTPATH}/scripts/npm_app_prepare_${slug}.sh ]]; then
			run_script "npm_app_prepare_${slug}" "${slug}.${domain}" || \
				warn "${slug} prepare hook reported errors; continuing."
		fi

		# Per-app advanced_config (only jellyfin currently needs one).
		advanced=""
		if [[ -f ${SCRIPTPATH}/scripts/npm_host_template_${slug}.sh ]]; then
			advanced=$(run_script "npm_host_template_${slug}" || true)
		fi

		run_script 'npm_host_create' "${slug}" "${port}" "${slug}.${domain}" "${advanced}" "0" || {
			warn "Failed to create NPM host for ${slug}; continuing."
			continue
		}
		run_script 'npm_cert_request_http01' "${slug}.${domain}" || true
	done < "${COMPOSE_ENV}"

	notice "integrate_npm complete."
}

_integrate_npm_pick_port() {
	# Echo the first <NAME>__PORT_<N> value found in the compose env.
	# Pick the lowest-numbered port (usually the main HTTP port).
	local name=${1-}
	local lowest_port=""
	local lowest_value=""
	local var value
	while IFS='=' read -r var value; do
		[[ ${var} =~ ^${name}__PORT_([0-9]+)$ ]] || continue
		local n="${BASH_REMATCH[1]}"
		if [[ -z ${lowest_port} || ${n} -lt ${lowest_port} ]]; then
			lowest_port="${n}"
			lowest_value="${value}"
		fi
	done < <(grep -E "^${name}__PORT_[0-9]+=" "${COMPOSE_ENV}" 2> /dev/null || true)
	# Prefer the container port (the suffix on PORT_<N>); the value
	# is what's published on the host, but inside the NPM network the
	# container is reached on its declared port.
	if [[ -n ${lowest_port} ]]; then
		printf '%s\n' "${lowest_port}"
	fi
}

test_integrate_npm() {
	warn "CI does not test integrate_npm (requires a running stack)."
}
