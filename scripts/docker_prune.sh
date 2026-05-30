#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

docker_prune() {
	local Title="Docker Prune"
	Question="Would you like to remove all unused containers, networks, volumes, images and build cache?"
	YesNotice="Removing unused docker resources."
	NoNotice="Nothing will be removed."

	local -a Command=(docker system prune --all --force --volumes)
	local CommandText
	CommandText=$(printf "%q " "${Command[@]}" | xargs)
	if run_script 'question_prompt' Y "${Question}" "${Title}" "${ASSUMEYES:+Y}"; then
		#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
		local -i PipeFD PipePID
		tui_pipe_open PipeFD PipePID "{{|TitleSuccess|}}${Title}" "${YesNotice}{{[-]}}\n{{|CommandLine|}} ${CommandText}"
		{
			{
				notice "${YesNotice}"
				RunAndLog notice "docker:notice" \
					error "Failed to remove unused docker resources." \
					"${Command[@]}"
			} || true
		} >&${PipeFD} 2>&1
		tui_pipe_close PipeFD PipePID
	else
		#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
		local -i PipeFD PipePID
		tui_pipe_open PipeFD PipePID "{{|TitleError|}}${Title}" "${NoNotice}"
		{ notice "${NoNotice}" || true; } >&${PipeFD} 2>&1
		tui_pipe_close PipeFD PipePID
	fi
}

test_docker_prune() {
	run_script 'docker_prune'
}
