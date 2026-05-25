#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_xml_get() {
	# config_xml_get XPath ConfigFile
	local result
	run_script 'config_xml_get_into' result "$@" || return 1
	printf '%s' "${result}"
}

test_config_xml_get() {
	warn "CI does not test config_xml_get."
}
