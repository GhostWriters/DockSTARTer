#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

npm_app_prepare_sabnzbd() {
	# npm_app_prepare_sabnzbd Hostname
	# Adds Hostname to SABnzbd's host_whitelist in sabnzbd.ini.
	# Without this, SABnzbd returns HTTP 403 to NPM-proxied requests.
	local hostname=${1-}
	local config="${DOCKER_VOLUME_CONFIG}/sabnzbd/sabnzbd.ini"

	if [[ -z ${hostname} ]]; then
		error "npm_app_prepare_sabnzbd requires a hostname."
		return 1
	fi
	if [[ ! -f ${config} ]]; then
		notice "sabnzbd config not present; skipping host_whitelist edit."
		return 0
	fi

	local current
	current=$(awk -F'[[:space:]]*=[[:space:]]*' '/^\[misc\]/{f=1;next} /^\[/{f=0} f && $1=="host_whitelist"{print $2; exit}' "${config}" || true)

	if [[ ",${current}," == *",${hostname},"* ]]; then
		return 0
	fi

	local new_value="${hostname}"
	if [[ -n ${current} ]]; then
		new_value="${current%,}, ${hostname}"
	fi

	# host_whitelist lives in [misc]; awk-edit in place.
	local TempFile
	TempFile=$(mktemp -t "${APPLICATION_NAME}.sabnzbd_prepare.XXXXXXXXXX")
	awk -v val="${new_value}" '
		BEGIN { in_misc = 0; written = 0 }
		/^\[misc\]/ { in_misc = 1; print; next }
		/^\[/ { if (in_misc && !written) { print "host_whitelist = " val; written = 1 } in_misc = 0; print; next }
		in_misc && /^host_whitelist[[:space:]]*=/ { print "host_whitelist = " val; written = 1; next }
		{ print }
		END { if (in_misc && !written) print "host_whitelist = " val }
	' "${config}" > "${TempFile}" && mv "${TempFile}" "${config}"

	notice "SABnzbd host_whitelist updated to include {{|Url|}}${hostname}{{[-]}}."
}

test_npm_app_prepare_sabnzbd() {
	warn "CI does not test npm_app_prepare_sabnzbd (requires config file)."
}
