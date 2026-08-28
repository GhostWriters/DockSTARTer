#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	find
)

app_list_hasvarfile() {
	# A multi-service app can have more than one ".env.app.*" file (the
	# plain file, any real per-service file, any shared/virtual file) --
	# sort -u so it's listed once per app, not once per file.
	${FIND} "${COMPOSE_FOLDER}" -maxdepth 1 -type f -name '.env.app.*' ! -name '.env.app.' 2> /dev/null |
		tr -s '\n' |
		run_script 'varfile_to_appname_pipe' |
		sort -u
}

test_app_list_hasvarfile() {
	run_script 'app_list_hasvarfile'
}
