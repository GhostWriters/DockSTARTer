#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Lists every ".env.app.*" var file belonging to APPNAME -- the plain
# file, and (for a multi-service app) any real per-service or shared/
# virtual files alongside it. Mirrors DockSTARTer2's --env-appfiles.
env_appfiles() {
	local -l appname=${1-}
	local -a Files
	run_script 'appvars_filelist_into' Files "${appname}"
	if [[ -z ${Files[*]-} ]]; then
		notice "No .env.app.* files found for '{{|App|}}${appname}{{[-]}}'."
		return
	fi
	printf '%s\n' "${Files[@]}"
}

test_env_appfiles() {
	notice "[immich]"
	run_script 'env_appfiles' immich
	notice "[watchtower]"
	run_script 'env_appfiles' watchtower
	notice "[nonexistentapp]"
	run_script 'env_appfiles' nonexistentapp
}
