#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

npm_app_prepare_qbittorrent() {
	# npm_app_prepare_qbittorrent [_]
	# Two changes to qBittorrent.conf:
	#  - WebUI\HostHeaderValidation=false   (allow proxied requests)
	#  - WebUI\AuthSubnetWhitelistEnabled=true
	#  - WebUI\AuthSubnetWhitelist=<docker_network_cidr>
	# Lets arr containers reach qbit's API without a password
	# (standard TRaSH-Guides pattern). User-facing UI auth stays.
	local config="${DOCKER_VOLUME_CONFIG}/qbittorrent/qBittorrent/config/qBittorrent.conf"
	if [[ ! -f ${config} ]]; then
		notice "qBittorrent config not present; skipping NPM-prep edits."
		return 0
	fi

	# Use the LAN network as the default trusted subnet. The arrs share
	# this network as long as they're on the same compose project, which
	# they are in DockSTARTer's default topology.
	local subnet=""
	run_script 'env_get_into' subnet "GLOBAL_LAN_NETWORK" 2> /dev/null || true
	if [[ -z ${subnet} ]]; then
		subnet="172.16.0.0/12"
	fi

	run_script 'config_ini_set' "WebUI\\HostHeaderValidation" "false" "${config}"
	run_script 'config_ini_set' "WebUI\\AuthSubnetWhitelistEnabled" "true" "${config}"
	run_script 'config_ini_set' "WebUI\\AuthSubnetWhitelist" "${subnet}" "${config}"

	notice "qBittorrent prepared for NPM proxy (auth bypassed for ${subnet})."
}

test_npm_app_prepare_qbittorrent() {
	warn "CI does not test npm_app_prepare_qbittorrent (requires config file)."
}
