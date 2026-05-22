#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
)

var_helpline() {
	local result
	run_script 'var_helpline_into' result "${1-}"
	printf '%s\n' "${result}"
}

test_var_helpline() {
	notice "[DOCKER_GID]                    = [$(run_script 'var_helpline' DOCKER_GID)]"
	notice "[TZ]                            = [$(run_script 'var_helpline' TZ)]"
	notice "[GLOBAL_LAN_NETWORK]            = [$(run_script 'var_helpline' GLOBAL_LAN_NETWORK)]"
	notice "[SONARR__ENABLED]               = [$(run_script 'var_helpline' SONARR__ENABLED)]"
	notice "[SONARR__NETWORK_MODE]          = [$(run_script 'var_helpline' SONARR__NETWORK_MODE)]"
	notice "[SONARR__VOLUME_CONFIG]         = [$(run_script 'var_helpline' SONARR__VOLUME_CONFIG)]"
	notice "[SONARR__PORT_0]                = [$(run_script 'var_helpline' SONARR__PORT_0)]"
	notice "[SONARR:SONARR__ENABLED]        = [$(run_script 'var_helpline' 'SONARR:SONARR__ENABLED')]"
	notice "[SONARR__4K__ENABLED]           = [$(run_script 'var_helpline' SONARR__4K__ENABLED)]"
	notice "[SONARR__UNKNOWN]               = [$(run_script 'var_helpline' SONARR__UNKNOWN)]"
}
