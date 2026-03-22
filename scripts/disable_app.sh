#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

disable_app() {
	# Disable the list of apps given.  Apps will be seperate arguments and/or seperated by spaces
	local AppList
	AppList="$(xargs -n 1 <<< "$*")"
	for APPNAME in ${AppList^^}; do
		local AppName
		AppName="$(run_script app_nicename "${APPNAME}")"
		if run_script 'app_is_builtin' "${APPNAME}"; then
			EnabledVar="${APPNAME}__ENABLED"
			info "Disabling application '{{|App|}}${AppName}{{[-]}}'"
			notice "Setting variable in {{|File|}}${COMPOSE_ENV}{{[-]}}:"
			notice "   {{|Var|}}${EnabledVar}='false'{{[-]}}"
			run_script 'env_set' "${EnabledVar}" false
		else
			warn "Application '{{|App|}}${AppName}{{[-]}}' does not exist."
		fi
	done
}

test_disable_app() {
	#run_script 'disable_app' watchtower "samba radarr"
	#cat "${COMPOSE_ENV}"
	warn "CI does not test disable_app."
}
