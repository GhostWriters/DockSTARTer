#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

set_permissions() {
	local CH_PATH=${1:-$SCRIPTPATH}
	case "${CH_PATH}" in
		# https://en.wikipedia.org/wiki/Unix_filesystem
		# Split into two in order to keep the lines shorter
		"/" | "/bin" | "/boot" | "/dev" | "/etc" | "/home" | "/lib" | "/media") ;&
		"/mnt" | "/opt" | "/proc" | "/root" | "/sbin" | "/srv" | "/sys" | "/tmp" | "/unix") ;&
		"/usr" | "/usr/include" | "/usr/lib" | "/usr/libexec" | "/usr/local" | "/usr/share") ;&
		"/var" | "/var/log" | "/var/mail" | "/var/spool" | "/var/tmp")
			error "Skipping permissions on '{{|Folder|}}${CH_PATH}{{[-]}}' because it is a system path."
			return
			;;
		${DETECTED_HOMEDIR}/*)
			info "Setting permissions for '{{|Folder|}}${CH_PATH}{{[-]}}'"
			;;
		*)
			# TODO: Consider adding a prompt to confirm setting permissions
			warn "Setting permissions for '{{|Folder|}}${CH_PATH}{{[-]}}' outside of '{{|Folder|}}${DETECTED_HOMEDIR}{{[-]}}' may be unsafe."
			;;
	esac
	local CH_PUID=${2:-$DETECTED_PUID}
	local CH_PGID=${3:-$DETECTED_PGID}
	if [[ ${CH_PUID} -ne 0 ]] && [[ ${CH_PGID} -ne 0 ]]; then
		info "Taking ownership of '{{|Folder|}}${CH_PATH}{{[-]}}' for user '{{|User|}}${CH_PUID}{{[-]}}' and group '{{|User|}}${CH_PGID}{{[-]}}'"
		sudo chown -R "${CH_PUID}":"${CH_PGID}" "${CH_PATH}" &> /dev/null || true
		info "Setting file and folder permissions in '{{|Folder|}}${CH_PATH}{{[-]}}'"
		sudo chmod -R a=,a+rX,u+w,g+w "${CH_PATH}" &> /dev/null || true
	fi
	info "Setting executable permission on '{{|File|}}${SCRIPTNAME}{{[-]}}'"
	sudo chmod +x "${SCRIPTNAME}" &> /dev/null ||
		fatal \
			"'{{|UserCommand|}}${APPLICATION_COMMAND}{{[-]}}' must be executable." \
			"Failing command: {{|FailingCommand|}}sudo chmod +x \"${SCRIPTNAME}\""
}

test_set_permissions() {
	run_script 'set_permissions'
}
