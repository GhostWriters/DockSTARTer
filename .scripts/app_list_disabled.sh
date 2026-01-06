#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
)

app_list_disabled() {
	local APPNAME_REGEX='[A-Z][A-Z0-9]*(__[A-Z0-9]+)?'
	local -a DISABLED_APPS
	local -a BUILTIN_APPS

	readarray -t DISABLED_APPS < <(
		${GREP} --color=never -o -P "^${APPNAME_REGEX}(?=__ENABLED\s*=(?!(?<quote>['|\"]?)(?i:on|true|yes)\k<quote>))" "${COMPOSE_ENV}" | sort || true
	)
	readarray -t BUILTIN_APPS < <(run_script 'app_list_builtin')
	local -a COMBINED=("${DISABLED_APPS[@]}" "${BUILTIN_APPS[@]}")
	printf "%s\n" "${COMBINED[@]}" | sort | uniq -d
}

test_app_list_disabled() {
	# run_script 'app_list_disabled'
	warn "CI does not test app_list_disabled."
}
