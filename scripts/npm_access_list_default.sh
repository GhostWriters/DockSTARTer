#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

npm_access_list_default() {
	# npm_access_list_default
	# Creates (idempotently) an NPM access-list called 'dockstarter-admin'
	# containing basic-auth credentials derived from the rotated NPM
	# admin email/password in api_keys.toml. Used to gate npm.<domain>
	# so the NPM admin UI is never published unauthenticated.
	#
	# Returns the access-list ID via stdout (caller can capture).
	local existing_id=""
	run_script 'api_key_get_into' existing_id "nginxproxymanager.access_lists.dockstarter_admin" 2> /dev/null || true
	if [[ -n ${existing_id} ]]; then
		printf '%s\n' "${existing_id}"
		return 0
	fi

	local email password
	if ! run_script 'api_key_get_into' email "nginxproxymanager.admin_email" \
		|| ! run_script 'api_key_get_into' password "nginxproxymanager.admin_password"; then
		error "Cannot create default access-list: NPM not bootstrapped yet."
		return 1
	fi

	local token
	if ! run_script 'npm_token_get_into' token; then
		return 1
	fi

	local username="${email%%@*}"
	local body
	body=$(jq -n \
		--arg uname "${username}" \
		--arg pass "${password}" \
		'{
			name: "dockstarter-admin",
			satisfy_any: false,
			pass_auth: true,
			items: [{ username: $uname, password: $pass }],
			clients: []
		}')

	local response
	if ! response=$(run_script 'http_request' "POST" \
		"http://nginxproxymanager:81/api/nginx/access-lists" \
		"${body}" "Authorization: Bearer ${token}"); then
		error "Failed to create default NPM access-list."
		return 1
	fi

	local new_id
	new_id=$(printf '%s' "${response}" | sed '$d' | jq -r '.id // empty')
	if [[ -z ${new_id} ]]; then
		error "NPM access-list response did not contain an id."
		return 1
	fi

	run_script 'api_key_set' "nginxproxymanager.access_lists.dockstarter_admin" "${new_id}"
	printf '%s\n' "${new_id}"
}

test_npm_access_list_default() {
	warn "CI does not test npm_access_list_default (requires a running NPM)."
}
