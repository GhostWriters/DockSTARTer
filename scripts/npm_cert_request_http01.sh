#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	curl
	dig
)

npm_cert_request_http01() {
	# npm_cert_request_http01 Hostname
	#
	# DNS preflight, then requests a Let's Encrypt cert from NPM
	# via HTTP-01 and attaches it to the proxy host for Hostname.
	#
	# If the hostname does not resolve to this host's public IP,
	# logs a warning and returns 0 — the caller proceeds with an
	# HTTP-only host. Avoids burning LE rate-limit attempts on
	# doomed requests.
	#
	# Stores the cert id in api_keys.toml under
	# nginxproxymanager.certs.<sanitised-hostname> for idempotency.
	local hostname=${1-}
	if [[ -z ${hostname} ]]; then
		error "npm_cert_request_http01 requires a hostname."
		return 1
	fi

	local resolved public_ip
	resolved=$(dig +short "${hostname}" 2> /dev/null | tail -1 || true)
	public_ip=$(curl -s --max-time 10 https://ifconfig.io 2> /dev/null || true)
	if [[ -z ${resolved} || -z ${public_ip} || ${resolved} != "${public_ip}" ]]; then
		warn "DNS preflight failed for {{|Url|}}${hostname}{{[-]}} (resolved=${resolved:-<none>}, public=${public_ip:-<unknown>}). Skipping cert request; proxy host will serve HTTP only."
		return 0
	fi

	local cert_email=""
	run_script 'env_get_into' cert_email "GLOBAL_CERT_EMAIL" 2> /dev/null || true
	if [[ -z ${cert_email} ]]; then
		warn "GLOBAL_CERT_EMAIL is empty; cannot request cert for ${hostname}."
		return 0
	fi

	local token
	if ! run_script 'npm_token_get_into' token; then
		error "Could not acquire NPM token for cert request."
		return 1
	fi

	local safe_host="${hostname//./_}"
	local existing_cert=""
	run_script 'api_key_get_into' existing_cert "nginxproxymanager.certs.${safe_host}" 2> /dev/null || true
	if [[ -n ${existing_cert} ]]; then
		notice "Cert for {{|Url|}}${hostname}{{[-]}} already requested (id ${existing_cert}); skipping."
		return 0
	fi

	local body
	body=$(jq -n \
		--arg host "${hostname}" \
		--arg email "${cert_email}" \
		'{
			provider: "letsencrypt",
			nice_name: $host,
			domain_names: [$host],
			meta: {
				letsencrypt_email: $email,
				letsencrypt_agree: true,
				dns_challenge: false
			}
		}')

	local response
	if ! response=$(run_script 'http_request' "POST" \
		"http://nginxproxymanager:81/api/nginx/certificates" \
		"${body}" "Authorization: Bearer ${token}"); then
		warn "Cert request for ${hostname} failed; proxy host will serve HTTP only."
		return 0
	fi

	local cert_id
	cert_id=$(printf '%s' "${response}" | sed '$d' | jq -r '.id // empty')
	if [[ -z ${cert_id} ]]; then
		warn "NPM cert response did not contain an id for ${hostname}."
		return 0
	fi

	run_script 'api_key_set' "nginxproxymanager.certs.${safe_host}" "${cert_id}"
	notice "Let's Encrypt cert requested for {{|Url|}}${hostname}{{[-]}} (id ${cert_id})."
}

test_npm_cert_request_http01() {
	warn "CI does not test npm_cert_request_http01 (requires DNS + NPM + LE)."
}
