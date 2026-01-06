#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

docker_prune() {
	local Title="Docker Prune"
	Question="Would you like to remove all unused containers, networks, volumes, images and build cache?"
	YesNotice="Removing unused docker resources."
	NoNotice="Nothing will be removed."

	local Command="docker system prune --all --force --volumes"
	if run_script 'question_prompt' Y "${Question}" "${Title}" "${ASSUMEYES:+Y}"; then
		if use_dialog_box; then
			{
				notice "${YesNotice}"
				notice "Running: ${C["RunningCommand"]}${Command}${NC}"
				eval "${Command}" ||
					error \
						"Failed to remove unused docker resources." \
						"Failing command: ${C["FailingCommand"]}${Command}"
			} |& dialog_pipe "${DC["TitleSuccess"]-}${Title}" "${YesNotice}${DC["NC"]-}\n${DC["CommandLine"]-} ${Command}"
		else
			notice "${YesNotice}"
			notice "Running: ${C["RunningCommand"]}${Command}${NC}"
			eval "${Command}" ||
				error \
					"Failed to remove unused docker resources." \
					"Failing command: ${C["FailingCommand"]}${Command}"
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
