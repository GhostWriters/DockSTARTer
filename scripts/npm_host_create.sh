#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

npm_host_create() {
	# npm_host_create AppSlug ContainerPort Hostname [AdvancedConfig] [AccessListId]
	#
	# Creates (or updates) an NPM proxy host for AppSlug that points
	# at the live container name (read from <APPSLUG>__CONTAINER_NAME
	# in the compose .env) on ContainerPort, served at Hostname.
	#
	# Idempotency: looks up an existing host ID stored in api_keys.toml
	# under nginxproxymanager.hosts.<appslug>; if present, PUTs to update,
	# otherwise POSTs to create and records the new ID.
	local app_slug=${1-}
	local container_port=${2-}
	local hostname=${3-}
	local advanced_config=${4-}
	local access_list_id=${5:-0}

	if [[ -z ${app_slug} || -z ${container_port} || -z ${hostname} ]]; then
		error "npm_host_create requires AppSlug, ContainerPort, Hostname."
		return 1
	fi

	local container_name_var="${app_slug^^}__CONTAINER_NAME"
	local container_name=""
	run_script 'env_get_into' container_name "${container_name_var}" 2> /dev/null || true
	if [[ -z ${container_name} ]]; then
		container_name="${app_slug}"
	fi

	local token
	if ! run_script 'npm_token_get_into' token; then
		error "Could not acquire NPM token; skipping host for ${app_slug}."
		return 1
	fi

	local existing_id=""
	run_script 'api_key_get_into' existing_id "nginxproxymanager.hosts.${app_slug}" 2> /dev/null || true

	local body
	body=$(jq -n \
		--arg host "${hostname}" \
		--arg fhost "${container_name}" \
		--arg fport "${container_port}" \
		--arg adv "${advanced_config}" \
		--argjson acl "${access_list_id}" \
		'{
			domain_names: [$host],
			forward_scheme: "http",
			forward_host: $fhost,
			forward_port: ($fport|tonumber),
			access_list_id: $acl,
			certificate_id: 0,
			meta: {},
			advanced_config: $adv,
			locations: [],
			block_exploits: true,
			caching_enabled: false,
			allow_websocket_upgrade: true,
			http2_support: false,
			hsts_enabled: false,
			hsts_subdomains: false,
			ssl_forced: false
		}')

	local url method
	if [[ -n ${existing_id} ]]; then
		url="http://nginxproxymanager:81/api/nginx/proxy-hosts/${existing_id}"
		method="PUT"
	else
		url="http://nginxproxymanager:81/api/nginx/proxy-hosts"
		method="POST"
	fi

	local response
	if ! response=$(run_script 'http_request' "${method}" "${url}" "${body}" "Authorization: Bearer ${token}"); then
		error "NPM ${method} ${url} failed for ${app_slug}."
		return 1
	fi

	if [[ -z ${existing_id} ]]; then
		local new_id
		new_id=$(printf '%s' "${response}" | sed '$d' | jq -r '.id // empty')
		if [[ -n ${new_id} ]]; then
			run_script 'api_key_set' "nginxproxymanager.hosts.${app_slug}" "${new_id}"
		fi
	fi

	notice "NPM host {{|Url|}}${hostname}{{[-]}} -> ${container_name}:${container_port} ready."
}

test_npm_host_create() {
	warn "CI does not test npm_host_create (requires a running NPM)."
}
