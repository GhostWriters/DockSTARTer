#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

npm_token_get_into() {
	# npm_token_get_into OutVar
	# Returns a fresh JWT for NPM in OutVar using the admin email +
	# password stored in api_keys.toml. Caller is responsible for
	# ensuring NPM has been bootstrapped (so api_keys.toml has those
	# values). Tokens are valid for 24h; this helper does not cache
	# them — call as needed.
	local -n _ntgi_out_="${1}"
	assert_nameref_is_string "${1}"

	local email password
	if ! run_script 'api_key_get_into' email "nginxproxymanager.admin_email"; then
		error "NPM admin email not in api_keys.toml; run NPM bootstrap first."
		return 1
	fi
	if ! run_script 'api_key_get_into' password "nginxproxymanager.admin_password"; then
		error "NPM admin password not in api_keys.toml; run NPM bootstrap first."
		return 1
	fi

	local url="http://nginxproxymanager:81/api/tokens"
	local body
	body=$(printf '{"identity":"%s","secret":"%s"}' "${email}" "${password}")

	local response
	if ! response=$(run_script 'http_request' "POST" "${url}" "${body}"); then
		error "NPM token request failed."
		return 1
	fi

	# Response is JSON body followed by trailing HTTP_STATUS= line.
	# Extract just the JSON body (everything before the last line).
	local json_body
	json_body=$(printf '%s' "${response}" | sed '$d')
	local token
	token=$(printf '%s' "${json_body}" | jq -r '.token // empty')
	if [[ -z ${token} ]]; then
		error "NPM token response did not contain a token."
		return 1
	fi
	_ntgi_out_="${token}"
}

test_npm_token_get_into() {
	warn "CI does not test npm_token_get_into (requires a running NPM)."
}
