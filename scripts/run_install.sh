#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

run_install() {
	local Title="Install Dependencies"
	local CommandLine="${CURRENT_COMMANDLINE:-${APPLICATION_COMMAND} --install}"
	local Question="Install or update all {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} dependencies?"
	local YesNotice="Installing or updating all {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} dependencies."
	local NoNotice="Not installing or updating all {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} dependencies."
	if run_script 'question_prompt' Y "${Question}" "${Title}" "${ASSUMEYES:+Y}"; then
		#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
		local -i PipeFD PipePID
		tui_pipe_open PipeFD PipePID "{{|TitleSuccess|}}${Title}" "${YesNotice}\n{{|CommandLine|}} ${CommandLine}"
		{
			{
				notice "${YesNotice}"
				run_install_commands
			} || true
		} >&${PipeFD} 2>&1
		tui_pipe_close PipeFD PipePID
	else
		#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
		local -i PipeFD PipePID
		tui_pipe_open PipeFD PipePID "{{|TitleError|}}${Title}" "${NoNotice}"
		notice "${NoNotice}" >&${PipeFD} 2>&1
		tui_pipe_close PipeFD PipePID
	fi
}

run_install_commands() {
	run_script 'update_system'
	run_script 'require_docker'
	run_script 'setup_docker_group'
	run_script 'enable_docker_service'
	run_script 'request_reboot'
}

test_run_install() {
	run_script 'run_install'
}
