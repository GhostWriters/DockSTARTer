#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

npm_bootstrap() {
	# npm_bootstrap
	# First-run setup for NPM. Rotates the default credentials
	# (admin@example.com / changeme) to a generated email/password
	# pair sourced from GLOBAL_CERT_EMAIL and openssl rand.
	#
	# Required state:
	#   - GLOBAL_CERT_EMAIL is set (otherwise: skip with warning).
	#   - NPM container is running on the docker network and reachable
	#     at http://nginxproxymanager:81.
	#
	# Idempotency:
	#   - If api_keys.toml already has [nginxproxymanager] with both
	#     admin_email and admin_password, AND a token can be obtained
	#     with them, bootstrap is a no-op.
	#   - A `bootstrap_in_progress = true` sentinel is set BEFORE the
	#     rotation request and cleared after. If a previous run crashed
	#     mid-rotation, the sentinel is visible for manual recovery.
	if ! is_true "${GLOBAL_CERT_EMAIL:+true}" || [[ -z ${GLOBAL_CERT_EMAIL-} ]]; then
		# Re-read in case the env wasn't sourced
		local cert_email=""
		run_script 'env_get_into' cert_email "GLOBAL_CERT_EMAIL" 2> /dev/null || true
		if [[ -z ${cert_email} ]]; then
			warn "GLOBAL_CERT_EMAIL is empty; skipping NPM bootstrap."
			return 0
		fi
		export GLOBAL_CERT_EMAIL="${cert_email}"
	fi

	# Short-circuit if already bootstrapped and credentials work.
	local current_email current_pw
	if run_script 'api_key_get_into' current_email "nginxproxymanager.admin_email" \
		&& run_script 'api_key_get_into' current_pw "nginxproxymanager.admin_password"; then
		local probe
		if probe=$(run_script 'npm_token_get_into' probe 2> /dev/null) || [[ -n ${probe} ]]; then
			notice "NPM already bootstrapped (credentials in api_keys.toml are valid)."
			return 0
		fi
	fi

	local new_password
	new_password=$(openssl rand -base64 32 | tr -d '\n=' | tr '+/' '-_')

	# Sentinel BEFORE we touch NPM, so a crash mid-rotation is recoverable.
	run_script 'api_key_set' "nginxproxymanager.bootstrap_in_progress" "true"
	run_script 'api_key_set' "nginxproxymanager.admin_email" "${GLOBAL_CERT_EMAIL}"
	run_script 'api_key_set' "nginxproxymanager.admin_password" "${new_password}"

	# Step 1: get a JWT using the *default* creds.
	local default_body
	default_body='{"identity":"admin@example.com","secret":"changeme"}'
	local response token
	if ! response=$(run_script 'http_request' "POST" "http://nginxproxymanager:81/api/tokens" "${default_body}"); then
		error "Could not authenticate to NPM with default credentials; is NPM running and reachable at port 81?"
		return 1
	fi
	token=$(printf '%s' "${response}" | sed '$d' | jq -r '.token // empty')
	if [[ -z ${token} ]]; then
		error "NPM default-credentials token request did not return a token."
		return 1
	fi

	# Step 2: update the admin user (id=1) with the new email and name.
	local update_body
	update_body=$(jq -n --arg e "${GLOBAL_CERT_EMAIL}" \
		'{name:"DockSTARTer Admin", nickname:"admin", email:$e, roles:["admin"], is_disabled:false}')
	run_script 'http_request' "PUT" "http://nginxproxymanager:81/api/users/1" "${update_body}" \
		"Authorization: Bearer ${token}" > /dev/null || {
		error "Failed to update NPM admin user."
		return 1
	}

	# Step 3: rotate the password.
	local pw_body
	pw_body=$(jq -n --arg p "${new_password}" \
		'{type:"password", current:"changeme", secret:$p}')
	run_script 'http_request' "PUT" "http://nginxproxymanager:81/api/users/1/auth" "${pw_body}" \
		"Authorization: Bearer ${token}" > /dev/null || {
		error "Failed to rotate NPM admin password."
		return 1
	}

	# Clear the sentinel.
	run_script 'api_key_set' "nginxproxymanager.bootstrap_in_progress" ""
	notice "NPM bootstrap complete. Admin email: {{|Email|}}${GLOBAL_CERT_EMAIL}{{[-]}}"
}

test_npm_bootstrap() {
	warn "CI does not test npm_bootstrap (requires a running NPM)."
}
