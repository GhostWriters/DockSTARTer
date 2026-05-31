#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_toml_key_exists() {
	# config_toml_key_exists section_key [config_file]
	local _ctke_val_
	run_script 'config_toml_get_into' _ctke_val_ "$@"
}

test_config_toml_key_exists() {
	warn "CI does not test config_toml_key_exists."
}
