#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	curl
)

http_request() {
	# http_request METHOD URL [DATA] [AUTH_HEADER]
	#
	# METHOD: GET | POST | PUT | DELETE
	# URL:    full URL including scheme and port
	# DATA:   optional JSON body (sent as Content-Type: application/json)
	# AUTH_HEADER: optional full header value, e.g.
	#              "Authorization: Bearer ${JWT}" or "X-Api-Key: ${KEY}"
	#
	# Stdout: HTTP response body (always).
	# Return code: 0 if HTTP status was 2xx, non-zero otherwise.
	# A trailing line `HTTP_STATUS=<code>` is appended to stdout so the caller
	# can recover the status even on success.
	#
	# Implements retry-with-backoff for transient failures (connection refused,
	# timeouts) but does not retry HTTP error responses (4xx/5xx).
	local method=${1-}
	local url=${2-}
	local data=${3-}
	local auth_header=${4-}

	if [[ -z ${method} || -z ${url} ]]; then
		error "http_request requires METHOD and URL."
		return 2
	fi

	local -a curl_args=(
		--silent
		--show-error
		--location
		--max-time 30
		--retry 3
		--retry-delay 2
		--retry-connrefused
		--write-out '\nHTTP_STATUS=%{http_code}'
		-X "${method}"
	)

	if [[ -n ${auth_header} ]]; then
		curl_args+=(-H "${auth_header}")
	fi

	if [[ -n ${data} ]]; then
		curl_args+=(-H "Content-Type: application/json" --data "${data}")
	fi

	local response
	response=$(curl "${curl_args[@]}" "${url}" 2>&1) || {
		printf '%s\n' "${response}"
		return 1
	}

	printf '%s\n' "${response}"

	# Recover status code from the trailing line
	local status_line="${response##*$'\n'}"
	local status="${status_line#HTTP_STATUS=}"
	if [[ ${status} =~ ^2[0-9][0-9]$ ]]; then
		return 0
	fi
	return 1
}

test_http_request() {
	warn "CI does not test http_request (would require an outbound network call)."
}
