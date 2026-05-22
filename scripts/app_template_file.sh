#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_template_file() {
	local result
	run_script 'app_template_file_into' result "${1:-}" "${2:-}"
	printf '%s\n' "${result}"
}

test_app_template_file() {
	for appname in watchtower radarr; do
		for Template in "*.labels.yml" ".env"; do
			notice "[${appname}] [${Template}]"
			local TemplateFile
			TemplateFile="$(run_script 'app_template_file' "${appname}" "${Template}")"
			notice "[${TemplateFile}]"
			cat "${TemplateFile}"
		done
	done
}
