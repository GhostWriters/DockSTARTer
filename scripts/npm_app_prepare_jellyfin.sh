#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

npm_app_prepare_jellyfin() {
	# npm_app_prepare_jellyfin Hostname
	# Adds the hostname (and the NPM container IP) to Jellyfin's
	# <KnownProxies> in network.xml so X-Forwarded-For headers are
	# trusted. Without this, Jellyfin may refuse remote requests or
	# log spurious "untrusted proxy" warnings.
	local hostname=${1-}
	local config="${DOCKER_VOLUME_CONFIG}/jellyfin/config/network.xml"

	if [[ -z ${hostname} ]]; then
		error "npm_app_prepare_jellyfin requires a hostname."
		return 1
	fi
	if [[ ! -f ${config} ]]; then
		notice "jellyfin network.xml not present; skipping NPM-prep edits."
		return 0
	fi

	# KnownProxies is a list of <string> children; for simplicity we
	# add the hostname as the canonical entry. Resolver-side IP would
	# need DNS lookup at runtime; hostname-string entry works.
	local existing
	existing=$(xmlstarlet sel -t -v "//NetworkConfiguration/KnownProxies/string[text()='${hostname}']" "${config}" 2> /dev/null || true)
	if [[ -n ${existing} ]]; then
		return 0
	fi

	local TempFile
	TempFile=$(mktemp -t "${APPLICATION_NAME}.jellyfin_prepare.XXXXXXXXXX")
	if xmlstarlet sel -t -v "//NetworkConfiguration/KnownProxies" "${config}" &> /dev/null; then
		xmlstarlet ed -s "//NetworkConfiguration/KnownProxies" -t elem -n "string" -v "${hostname}" "${config}" > "${TempFile}"
	else
		xmlstarlet ed -s "//NetworkConfiguration" -t elem -n "KnownProxies" -v "" \
			-s "//NetworkConfiguration/KnownProxies" -t elem -n "string" -v "${hostname}" "${config}" > "${TempFile}"
	fi
	if [[ -s ${TempFile} ]]; then
		mv "${TempFile}" "${config}"
		notice "jellyfin KnownProxies updated to include {{|Url|}}${hostname}{{[-]}}."
	else
		rm -f "${TempFile}"
		warn "xmlstarlet produced empty output for jellyfin network.xml; not modifying."
	fi
}

test_npm_app_prepare_jellyfin() {
	warn "CI does not test npm_app_prepare_jellyfin (requires config file)."
}
