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
		if use_dialog_box; then
			{
				notice "${YesNotice}"
				RunAndLog notice notice \
					error "Failed to remove unused docker resources." \
					"${Command[@]}"
			} |& dialog_pipe "${DC["TitleSuccess"]-}${Title}" "${YesNotice}${DC["NC"]-}\n${DC["CommandLine"]-} ${CommandText}"
		else
			notice "${YesNotice}"
			RunAndLog notice notice \
				error "Failed to remove unused docker resources." \
				"${Command[@]}"
		fi
	else
		if use_dialog_box; then
			notice "${NoNotice}" |& dialog_pipe "${DC[TitleError]}${Title}" "${NoNotice}"
		else
			notice "${NoNotice}"
		fi
	fi
}

test_docker_prune() {
	run_script 'docker_prune'
}
