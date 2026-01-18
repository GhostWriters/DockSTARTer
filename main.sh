#!/usr/bin/env bash
shopt -s extdebug
set +o posix
set -Eeuo pipefail
IFS=$'\n\t'

declare -rgx APPLICATION_NAME='DockSTARTer'
declare -rgx APPLICATION_COMMAND='ds'
declare -rgx APPLICATION_REPO='https://github.com/GhostWriters/DockSTARTer'
declare -rgx APPLICATION_LEGACY_BRANCH='master'
declare -rgx APPLICATION_DEFAULT_BRANCH='main'
declare -rgx APPLICATION_FOLDER_NAME_DEFAULT='.dockstarter'

declare -rgx TEMPLATES_NAME='DockSTARTer-Templates'
declare -rgx TEMPLATES_REPO='https://github.com/GhostWriters/DockSTARTer-Templates'
declare -rgx TEMPLATES_DEFAULT_BRANCH='main'
declare -rgx TEMPLATES_PARENT_FOLDER_NAME='templates'
declare -rgx TEMPLATES_REPO_FOLDER_NAME='DockSTARTer-Templates'

# Version Functions
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash#comment92693604_4024263
vergte() { printf '%s\n%s' "${2}" "${1}" | sort -C -V; }
vergt() { ! vergte "${2}" "${1}"; }
verlte() { printf '%s\n%s' "${1}" "${2}" | sort -C -V; }
verlt() { ! verlte "${2}" "${1}"; }

# Check for supported bash version
declare REQUIRED_BASH_VERSION="4"
if verlt "${BASH_VERSION}" "${REQUIRED_BASH_VERSION}"; then
	echo "Unsupported bash version."
	echo "${APPLICATION_NAME} requires at least bash version ${REQUIRED_BASH_VERSION}, installed version is ${BASH_VERSION}."
	exit 1
fi

readonly -a ARGS=("$@")

# Github Token for CI
if [[ ${CI-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS-} == true ]]; then
	readonly GH_HEADER="Authorization: token ${GH_TOKEN}"
	export GH_HEADER
fi

declare DS_COMMAND
DS_COMMAND=$(command -v "${APPLICATION_COMMAND}" || true)

# User/Group Information
readonly DETECTED_PUID=${SUDO_UID:-$UID}
export DETECTED_PUID
DETECTED_UNAME=$(id -un "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_UNAME
export DETECTED_UNAME
DETECTED_PGID=$(id -g "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_PGID
export DETECTED_PGID
DETECTED_UGROUP=$(id -gn "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_UGROUP
export DETECTED_UGROUP
DETECTED_HOMEDIR=$(eval echo "~${DETECTED_UNAME}" 2> /dev/null || true)
readonly DETECTED_HOMEDIR
export DETECTED_HOMEDIR

# System Information
ARCH=$(uname -m)
if [[ ${ARCH} == arm64 ]]; then
	ARCH="aarch64"
fi
readonly ARCH
export ARCH

declare -A C DC

# Script Information
# https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself/246128#246128
get_scriptname() {
	# https://stackoverflow.com/questions/35006457/choosing-between-0-and-bash-source/35006505#35006505
	local SOURCE=${BASH_SOURCE[0]:-$0}
	while [[ -L ${SOURCE} ]]; do # resolve ${SOURCE} until the file is no longer a symlink
		local DIR
		DIR=$(cd -P "$(dirname "${SOURCE}")" > /dev/null 2>&1 && pwd)
		SOURCE=$(readlink "${SOURCE}")
		[[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" # if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	echo "${SOURCE}"
}

SCRIPTPATH=$(cd -P "$(dirname "$(get_scriptname)")" > /dev/null 2>&1 && pwd)
readonly SCRIPTPATH
export SCRIPTPATH
SCRIPTNAME="${SCRIPTPATH}/$(basename "$(get_scriptname)")"
readonly SCRIPTNAME
export SCRIPTNAME

[[ -z ${XDG_DATA_HOME-} ]] && declare -gx XDG_DATA_HOME="${DETECTED_HOMEDIR}/.local/share"
[[ -z ${XDG_CONFIG_HOME-} ]] && declare -gx XDG_CONFIG_HOME="${DETECTED_HOMEDIR}/.config"
[[ -z ${XDG_CACHE_HOME-} ]] && declare -gx XDG_CACHE_HOME="${DETECTED_HOMEDIR}/.cache"
[[ -z ${XDG_STATE_HOME-} ]] && declare -gx XDG_STATE_HOME="${DETECTED_HOMEDIR}/.local/state"
#[[ -z ${XDG_RUNTIME_DIR-} ]] && declare -gx XDG_RUNTIME_DIR="/run/user/${DETECTED_PUID}"
for XDG_FOLDER in "${XDG_DATA_HOME}" "${XDG_CONFIG_HOME}" "${XDG_CACHE_HOME}" "${XDG_STATE_HOME}" "${XDG_STATE_HOME}/${APPLICATION_NAME,,}"; do
	if [[ ! -d ${XDG_FOLDER} ]]; then
		if [[ -f ${XDG_FOLDER} ]]; then
			# XDG_FOLDER exists, but it's not a folder, so remove it
			sudo rm -f "${XDG_FOLDER}"
		fi
		mkdir -p "${XDG_FOLDER}"
		sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${XDG_FOLDER}"
		sudo chmod 700 "${XDG_FOLDER}"
	fi
done

declare -rgx APPLICATION_LOG="${XDG_STATE_HOME}/${APPLICATION_NAME,,}/${APPLICATION_NAME,,}.log"
declare -rgx FATAL_LOG="${XDG_STATE_HOME}/${APPLICATION_NAME,,}/fatal.log"
if [[ ${APPLICATION_LOG} != "${SCRIPTPATH}/${APPLICATION_NAME,,}.log" ]]; then
	if [[ ! -f ${APPLICATION_LOG} && -f "${SCRIPTPATH}/${APPLICATION_NAME,,}.log" ]]; then
		mv "${SCRIPTPATH}/${APPLICATION_NAME,,}.log" "${APPLICATION_LOG}" || true
	fi
fi
if [[ ${FATAL_LOG} != "${SCRIPTPATH}/fatal.log" ]]; then
	if [[ ! -f ${FATAL_LOG} && -f "${SCRIPTPATH}/fatal.log" ]]; then
		mv "${SCRIPTPATH}/fatal.log" "${FATAL_LOG}" || true
	fi
fi

# Terminal Colors
declare -Agr B=( # Background
	[B]=$(tput setab 4 2> /dev/null || echo -e "\e[44m") # Blue
	[C]=$(tput setab 6 2> /dev/null || echo -e "\e[46m") # Cyan
	[G]=$(tput setab 2 2> /dev/null || echo -e "\e[42m") # Green
	[K]=$(tput setab 0 2> /dev/null || echo -e "\e[40m") # Black
	[M]=$(tput setab 5 2> /dev/null || echo -e "\e[45m") # Magenta
	[R]=$(tput setab 1 2> /dev/null || echo -e "\e[41m") # Red
	[W]=$(tput setab 7 2> /dev/null || echo -e "\e[47m") # White
	[Y]=$(tput setab 3 2> /dev/null || echo -e "\e[43m") # Yellow
)
declare -Agr F=( # Foreground
	[B]=$(tput setaf 4 2> /dev/null || echo -e "\e[34m") # Blue
	[C]=$(tput setaf 6 2> /dev/null || echo -e "\e[36m") # Cyan
	[G]=$(tput setaf 2 2> /dev/null || echo -e "\e[32m") # Green
	[K]=$(tput setaf 0 2> /dev/null || echo -e "\e[30m") # Black
	[M]=$(tput setaf 5 2> /dev/null || echo -e "\e[35m") # Magenta
	[R]=$(tput setaf 1 2> /dev/null || echo -e "\e[31m") # Red
	[W]=$(tput setaf 7 2> /dev/null || echo -e "\e[37m") # White
	[Y]=$(tput setaf 3 2> /dev/null || echo -e "\e[33m") # Yellow
)

DM=$(tput dim 2> /dev/null || echo -e "\e[2m") # Dim
readonly DM
export DM
BD=$(tput bold 2> /dev/null || echo -e "\e[1m") # Bold
readonly BD
export BD
UL=$(tput smul 2> /dev/null || echo -e "\e[4m") # Underline
readonly UL
export UL
NC=$(tput sgr0 2> /dev/null || echo -e "\e[0m") # No Color
readonly NC
export NC
BS=$(tput cup 1000 0 2> /dev/null || true) # Bottom of screen
readonly BS
export BS

declare -Agr C=( # Pre-defined colors
	["Timestamp"]="${DM}"
	["Trace"]="${F[B]}"
	["Debug"]="${F[B]}"
	["Info"]="${F[B]}"
	["Notice"]="${F[G]}"
	["Warn"]="${F[Y]}"
	["Error"]="${F[R]}"
	["Fatal"]="${B[R]}${F[W]}"

	["FatalFooter"]="${NC}"
	["TraceHeader"]="${F[R]}"
	["TraceFooter"]="${F[R]}"
	["TraceFrameNumber"]="${F[R]}"
	["TraceFrameLines"]="${F[R]}"
	["TraceSourceFile"]="${F[C]}${BD}"
	["TraceLineNumber"]="${F[Y]}${BD}"
	["TraceFunction"]="${F[G]}${BD}"
	["TraceCmd"]="${F[G]}${BD}"
	["TraceCmdArgs"]="${F[G]}"

	["UnitTestPass"]="${F[G]}"
	["UnitTestFail"]="${F[R]}"
	["UnitTestFailArrow"]="${F[R]}"

	["App"]="${F[C]}"
	["ApplicationName"]="${F[C]}${BD}"
	["Branch"]="${F[C]}"
	["FailingCommand"]="${F[R]}"
	["File"]="${F[C]}${BD}"
	["Folder"]="${F[C]}${BD}"
	["Program"]="${F[C]}"
	["RunningCommand"]="${F[G]}${BD}"
	["Theme"]="${F[C]}"
	["Update"]="${F[G]}"
	["User"]="${F[C]}"
	["URL"]="${F[C]}${UL}"
	["UserCommand"]="${F[Y]}${BD}"
	["UserCommandError"]="${F[R]}${UL}"
	["Var"]="${F[M]}"
	["Version"]="${F[C]}"
	["Yes"]="${F[G]}"
	["No"]="${F[R]}"

	["UsageCommand"]="${F[Y]}${BD}"
	["UsageOption"]="${F[Y]}"
	["UsageApp"]="${F[C]}"
	["UsageBranch"]="${F[C]}"
	["UsageFile"]="${F[C]}${BD}"
	["UsagePage"]="${F[C]}${BD}"
	["UsageTheme"]="${F[C]}"
	["UsageVar"]="${F[M]}"
)

indent_text() {
	local -i IndentSize=${1}
	shift
	local IndentString
	printf -v IndentString "%*s" "${IndentSize}" ""
	local line
	while IFS= read -r line; do
		printf '%s%s\n' "${IndentString}" "${line}"
	done <<< "$(printf '%s\n' "$@")"
}

get_system_info() {
	local -a Output=()

	Output+=(
		"${C["ApplicationName"]-}${APPLICATION_NAME-}${NC-} [${C["Version"]-}${APPLICATION_VERSION-}${NC-}]"
		"${C["ApplicationName"]-}${TEMPLATES_NAME-}${NC-} [${C["Version"]-}${TEMPLATES_VERSION-}${NC-}]"
		""
		"Currently running as: $0 (PID $$)"
		"Shell name from /proc/$$/exe: $(readlink /proc/$$/exe)"
		""
		"ARCH:             ${ARCH-}"
		"SCRIPTPATH:       ${SCRIPTPATH-}"
		"SCRIPTNAME:       ${SCRIPTNAME-}"
		"COMPOSE_FOLDER:   ${COMPOSE_FOLDER-}"
		"CONFIG_FOLDER:    ${CONFIG_FOLDER-}"
		""
		"APPLICATION_INI_FILE: ${APPLICATION_INI_FILE-}"
		"DETECTED_PUID:    ${DETECTED_PUID-}"
		"DETECTED_UNAME:   ${DETECTED_UNAME-}"
		"DETECTED_PGID:    ${DETECTED_PGID-}"
		"DETECTED_UGROUP:  ${DETECTED_UGROUP-}"
		"DETECTED_HOMEDIR: ${DETECTED_HOMEDIR-}"
	)

	Output+=(
		""
		"${C["RunningCommand"]}echo \${BASH_VERSION}${NC}:"
		"${BASH_VERSION-}"
	)

	[[ -f /etc/os-release ]] &&
		Output+=(
			""
			"${C["RunningCommand"]}cat /etc/os-release${NC}:"
			"$(cat /etc/os-release)"
		)

	[[ -f /etc/lsb-release ]] &&
		Output+=(
			""
			"${C["RunningCommand"]}cat /etc/lsb-release${NC}:"
			"$(cat /etc/lsb-release)"
		)

	command -v lsb_release &> /dev/null &&
		Output+=(
			""
			"${C["RunningCommand"]}lsb_release -a${NC}:"
			"$(lsb_release -a)"
		)

	command -v uname &> /dev/null &&
		Output+=(
			""
			"${C["RunningCommand"]}uname -a${NC}:"
			"$(uname -a)"
		)

	command -v system_profiler &> /dev/null &&
		Output+=(
			""
			"${C["RunningCommand"]}system_profiler SPSoftwareDataType${NC}:"
			"$(system_profiler SPSoftwareDataType)"
		)

	printf '%s\n' "${Output[@]}"
}

# Log Functions
MKTEMP_LOG=$(mktemp -t "${APPLICATION_NAME}.log.XXXXXXXXXX") || echo -e "Failed to create temporary log file.\nFailing command: ${C["FailingCommand"]}mktemp -t \"${APPLICATION_NAME}.log.XXXXXXXXXX\""
readonly MKTEMP_LOG
echo "DockSTARTer Log" > "${MKTEMP_LOG}"
log() {
	local ToTerm=${1-}
	local Message=${2-}
	local StrippedMessage=${Message}
	if declare -F strip_ansi_colors > /dev/null; then
		StrippedMessage=$(strip_ansi_colors "${StrippedMessage-}")
	fi
	if [[ -n ${ToTerm} ]]; then
		if [[ -t 2 ]]; then
			# Stderr is not being redirected, output with color
			printf '%s\n' "${Message}" >&2
		else
			# Stderr is being redirected, output without color
			printf '%s\n' "${StrippedMessage}" >&2
		fi
	fi
	# Output the message to the log file without color
	printf '%s\n' "${StrippedMessage}" >> "${MKTEMP_LOG}" || true
}
timestamped_log() {
	local LogLevelTag=${1-}
	shift 1
	local LogMessage
	LogMessage=$(printf '%b\n' "$@")
	# Create a notice for each argument passed to the function
	local Timestamp
	Timestamp=$(date +"%F %T")
	# Create separate notices with the same timestamp for each line in a log message
	local line
	while IFS= read -r line; do
		printf "${NC}${C["Timestamp"]-}${Timestamp}${NC-} ${LogLevelTag}   %s${NC}\n" "${line}"
	done <<< "${LogMessage}"
}
trace() { log "${TRACE-}" "$(timestamped_log "${C["Trace"]-}[TRACE ]${NC-}" "$@")"; }
debug() { log "${DEBUG-}" "$(timestamped_log "${C["Debug"]-}[DEBUG ]${NC-}" "$@")"; }
info() { log "${VERBOSE-}" "$(timestamped_log "${C["Info"]-}[INFO  ]${NC-}" "$@")"; }
notice() { log true "$(timestamped_log "${C["Notice"]-}[NOTICE]${NC-}" "$@")"; }
warn() { log true "$(timestamped_log "${C["Warn"]-}[WARN  ]${NC-}" "$@")"; }
error() { log true "$(timestamped_log "${C["Error"]-}[ERROR ]${NC-}" "$@")"; }
fatal_notrace() {
	local LogMessage
	LogMessage=$(timestamped_log "${C["Fatal"]-}[FATAL ]${NC}" "$@")
	log true "${LogMessage}"
	if declare -F strip_ansi_colors > /dev/null; then
		LogMessage=$(strip_ansi_colors "${LogMessage-}")
	fi
	printf '%s\n' "${LogMessage}" > "${FATAL_LOG}" || true
	exit 1
}
fatal() {
	local -i thisFuncLine=$((LINENO - 1))

	local -a Stack=()

	readarray -t Stack < <(get_system_info)
	Stack+=("")

	local -i StackSize=${#FUNCNAME[@]}
	local -i FrameNumberLength=${#StackSize}
	local NoFile="<nofile>"
	local NoFunction="<nofunction>"

	# Pre-calculate Arg Offsets for LIFO BASH_ARGV (with extdebug)
	local -a ArgOffsets=()
	local -i Offset=0
	local -i j
	for ((j = 0; j < StackSize; j++)); do
		ArgOffsets[j]=${Offset}
		Offset+=${BASH_ARGC[j]-0}
	done

	local indent=""
	local -i i
	for ((i = StackSize - 1; i >= 0; i--)); do
		local func="${FUNCNAME[i]:-$NoFunction}"
		local SourceFile="${BASH_SOURCE[i]:-$NoFile}"
		local -i line="${thisFuncLine}"
		if ((i > 0)); then
			line="${BASH_LINENO[i - 1]:-0}"
		fi

		local prefix=""
		local arrowIndent="${indent}"
		if ((i < StackSize - 1)); then
			prefix="${C["TraceFrameLines"]}└>${NC}"
			if [[ ${#indent} -ge 2 ]]; then
				arrowIndent="${indent%  }"
			fi
		fi

		# Format: "Num: [Indent]Arrow File:Line (Function)"
		local StackLineFormat="${C["TraceFrameNumber"]}%${FrameNumberLength}d${NC}: ${arrowIndent}${prefix}${C["TraceSourceFile"]}%s${NC}:${C["TraceLineNumber"]}%d${NC} (${C["TraceFunction"]}%s${NC})"
		# shellcheck disable=SC2059 # Dynamic format string for padding
		Stack+=(
			"$(printf "${StackLineFormat}" "${i}" "${SourceFile##*/}" "${line}" "${func}")"
		)

		# Command and Arguments for this frame (Show what this frame CALLED)
		if ((i > 0)); then
			local next_i=$((i - 1))
			local cmd="${FUNCNAME[next_i]:-$NoFunction}"
			local -i CmdArgCount=${BASH_ARGC[next_i]-0}
			local -i CurrentArg=${ArgOffsets[next_i]-0}

			local FrameCmdPrefix="${C["TraceFrameLines"]}│${NC}"
			local FrameArgPrefix="${C["TraceFrameLines"]}│${NC}"

			local cmdString="${C["TraceCmd"]}${cmd}${NC}"
			local -a cmdArray=()
			cmdArray+=("${FrameCmdPrefix}${cmdString}")

			if [[ CmdArgCount -ne 0 ]]; then
				for ((j = CurrentArg + CmdArgCount - 1; j >= CurrentArg; j--)); do
					local cmdArgString="${BASH_ARGV[$j]}"
					cmdArgString="$(strip_ansi_colors "${cmdArgString}")"
					cmdArgString="${cmdArgString//\\/\\\\}"
					cmdArgString="${NC}«${C["TraceCmdArgs"]}${cmdArgString}${NC}»"
					while read -r cmdLine; do
						cmdArray+=(
							"${FrameArgPrefix}${C["TraceCmdArgs"]}${cmdLine}"
						)
					done <<< "${cmdArgString}"
				done
			fi

			# Align command block with the start of the frame text
			local -i StackCmdIndent=$((FrameNumberLength + 2 + ${#indent}))
			Stack+=(
				"$(indent_text ${StackCmdIndent} "${cmdArray[@]}")"
			)
		fi

		indent+="  "
	done

	fatal_notrace \
		"${C["TraceHeader"]}### BEGIN SYSTEM INFORMATION AND STACK TRACE ###" \
		"$(indent_text 2 "${Stack[@]}")" \
		"${C["TraceFooter"]}### END SYSTEM INFORMATION AND STACK TRACE ###" \
		"" \
		"$@" \
		"" \
		"${C["FatalFooter"]}Please let the dev know of this error." \
		"${C["FatalFooter"]}It has been written to '${C["File"]}${FATAL_LOG}${C["FatalFooter"]}', and appended to '${C["File"]}${APPLICATION_LOG}${C["FatalFooter"]}'."
}

[[ -f "${SCRIPTPATH}/.includes/misc_functions.sh" ]] && source "${SCRIPTPATH}/.includes/misc_functions.sh"
[[ -f "${SCRIPTPATH}/.includes/global_variables.sh" ]] && source "${SCRIPTPATH}/.includes/global_variables.sh"
[[ -f "${SCRIPTPATH}/.includes/pm_variables.sh" ]] && source "${SCRIPTPATH}/.includes/pm_variables.sh"
[[ -f "${SCRIPTPATH}/.includes/run_script.sh" ]] && source "${SCRIPTPATH}/.includes/run_script.sh"
[[ -f "${SCRIPTPATH}/.includes/dialog_functions.sh" ]] && source "${SCRIPTPATH}/.includes/dialog_functions.sh"
[[ -f "${SCRIPTPATH}/.includes/ds_functions.sh" ]] && source "${SCRIPTPATH}/.includes/ds_functions.sh"
[[ -f "${SCRIPTPATH}/.includes/test_functions.sh" ]] && source "${SCRIPTPATH}/.includes/test_functions.sh"
[[ -f "${SCRIPTPATH}/.includes/usage.sh" ]] && source "${SCRIPTPATH}/.includes/usage.sh"
[[ -f "${SCRIPTPATH}/.includes/cmdline.sh" ]] && source "${SCRIPTPATH}/.includes/cmdline.sh"

# Check for supported CPU architecture
check_arch() {
	if [[ ${ARCH} != "arm64" ]] && [[ ${ARCH} != "aarch64" ]] && [[ ${ARCH} != "x86_64" ]]; then
		fatal_notrace \
			"Unsupported architecture." \
			"Supported architectures are 'aarch64' or 'x86_64', running architecture is '${ARCH}'."
	fi
}

# Check if the repo exists relative to the SCRIPTPATH
check_repo() {
	if [[ -d ${SCRIPTPATH}/.git ]] && [[ -d ${SCRIPTPATH}/.includes ]] && [[ -d ${SCRIPTPATH}/.scripts ]]; then
		return
	else
		return 1
	fi
}

# Check if the templates repo exists relative to the ${TEMPLATES_PARENT_FOLDER}
check_templates_repo() {
	if [[ -d ${TEMPLATES_PARENT_FOLDER}/.git ]]; then
		return
	else
		return 1
	fi
}
# Check if running as root
check_root() {
	if [[ ${DETECTED_PUID} == "0" ]] || [[ ${DETECTED_HOMEDIR} == "/root" ]]; then
		fatal_notrace \
			"Running as '${C["User"]-}root${NC-}' is not supported." \
			"Please run as a standard user."
	fi
}

# Check if running with sudo
check_sudo() {
	if [[ ${EUID} -eq 0 ]]; then
		fatal_notrace \
			"Running with '${C["UserCommand"]-}sudo${NC-}' is not supported." \
			"Commands requiring '${C["UserCommand"]-}sudo${NC-}' will prompt automatically when required."
	fi
}
clone_repo() {
	warn \
		"Attempting to clone ${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} repo to '${C["Folder"]-}${DETECTED_HOMEDIR}/${APPLICATION_FOLDER_NAME_DEFAULT}${NC-}' location."
	git clone -b "${APPLICATION_DEFAULT_BRANCH}" "${APPLICATION_REPO}" "${DETECTED_HOMEDIR}/${APPLICATION_FOLDER_NAME_DEFAULT}" ||
		fatal \
			"Failed to clone ${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} repo." \
			"Failing command: ${C["FailingCommand"]-}git clone -b \"${APPLICATION_DEFAULT_BRANCH}\" \"${APPLICATION_REPO}\" \"${DETECTED_HOMEDIR}/${APPLICATION_FOLDER_NAME_DEFAULT}\""
	if [[ ${#ARGS[@]} -eq 0 ]]; then
		notice \
			"Performing first run install."
		exec bash "${DETECTED_HOMEDIR}/${APPLICATION_FOLDER_NAME_DEFAULT}/main.sh" -yvi --config-show
	else
		exec bash "${DETECTED_HOMEDIR}/${APPLICATION_FOLDER_NAME_DEFAULT}/main.sh" "${ARGS[@]}"
	fi
}

clone_templates_repo() {
	warn \
		"Attempting to clone ${C["ApplicationName"]-}${TEMPLATES_NAME}${NC-} repo to '${C["Folder"]-}${TEMPLATES_PARENT_FOLDER}${NC-}' location."
	if [[ -d ${TEMPLATES_PARENT_FOLDER?} ]]; then
		sudo rm -rf "${TEMPLATES_PARENT_FOLDER?}" ||
			fatal \
				"Failed to remove ${TEMPLATES_PARENT_FOLDER?}." \
				"Failing command: ${C["FailingCommand"]-}rm -rf \"${TEMPLATES_PARENT_FOLDER?}\""
	fi
	git clone -b "${TEMPLATES_DEFAULT_BRANCH}" "${TEMPLATES_REPO}" "${TEMPLATES_PARENT_FOLDER}" ||
		fatal \
			"Failed to clone ${C["ApplicationName"]-}${TEMPLATES_NAME}${NC-} repo." \
			"Failing command: ${C["FailingCommand"]-}git clone -b \"${TEMPLATES_DEFAULT_BRANCH}\" \"${TEMPLATES_REPO}\" \"${TEMPLATES_PARENT_FOLDER}\""
}

# Cleanup Function
cleanup() {
	local -ri EXIT_CODE=$?
	trap - ERR EXIT SIGABRT SIGALRM SIGHUP SIGINT SIGQUIT SIGTERM

	if [[ -e ${APPLICATION_LOG} ]]; then
		sudo chown "${DETECTED_PUID}:${DETECTED_PGID}" "${APPLICATION_LOG}" || true
	fi
	cat "${MKTEMP_LOG:-/dev/null}" >> "${APPLICATION_LOG}" || true
	if [[ -n ${MKTEMP_LOG-} && -f ${MKTEMP_LOG} ]]; then
		sudo rm -f "${MKTEMP_LOG}" &> /dev/null || true
	fi
	tail -1000 "${APPLICATION_LOG}" | tee "${APPLICATION_LOG}" > /dev/null || true
	if [[ -n ${APPLICATION_CACHE_FOLDER-} && -d ${APPLICATION_CACHE_FOLDER} ]]; then
		sudo rm -rf "${APPLICATION_CACHE_FOLDER?}" &> /dev/null || true
	fi
	sudo -E chmod +x "${SCRIPTNAME}" &> /dev/null || true

	if [[ ${CI-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS-} == false ]]; then
		echo "TRAVIS_SECURE_ENV_VARS is false for Pull Requests from remote branches. Please retry failed builds!"
	fi

	if [[ ${EXIT_CODE} -ne 0 ]]; then
		echo "${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} did not finish running successfully."
	fi
	if [[ ${PROMPT:-CLI} == "GUI" ]]; then
		# Try to restore the terminal to a working state
		stty cooked echo
		# Move the cursor to the bottom of the screen
		echo -n "${BS}"
	fi

	exit ${EXIT_CODE}
}
trap 'cleanup' ERR EXIT SIGABRT SIGALRM SIGHUP SIGINT SIGQUIT SIGTERM

declare -gx APPLICATION_VERSION="Unknown Version"
declare -gx TEMPLATES_VERSION="Unknown Version"
if check_repo; then
	if declare -F ds_version > /dev/null; then
		APPLICATION_VERSION="$(ds_version)"
		if [[ -z ${APPLICATION_VERSION} ]]; then
			APPLICATION_VERSION="$(ds_branch) Unknown Version"
		fi
	fi
	if declare -F templates_version > /dev/null; then
		TEMPLATES_VERSION="$(templates_version)"
		if [[ -z ${TEMPLATES_VERSION} ]]; then
			TEMPLATES_VERSION="$(templates_branch) Unknown Version"
		fi
	fi
fi

init_check_system() {
	check_arch
	# Terminal Check
	if [[ -t 1 ]]; then
		check_root
		check_sudo
	fi
}

init_check_cloned() {
	if ! check_repo; then
		clone_repo
	fi
}

init_check_tty() {
	# Check if tty is writable
	if [[ ${CI-} != true && ! -w $(tty) ]]; then
		case "$(uname -s)" in
			Linux) exec script -qefc "$(printf "%q " "$0" "${ARGS[@]}")" /dev/null ;;
			Darwin) exec script -q /dev/null "$0" "${ARGS[@]}" ;;
			*)
				error \
					"The TTY is not writable." \
					"${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} requires a writable TTY."
				exit 1
				;;
		esac
	fi
}
init_check_templates() {
	if ! check_templates_repo; then
		clone_templates_repo
	fi
}

init_check_dependencies() {
	run_script 'package_manager_init'
	if [[ -v PM && -v PM_${PM^^}_COMMAND_DEPS ]]; then
		declare -n COMMAND_DEPS="PM_${PM^^}_COMMAND_DEPS"
	else
		declare -n COMMAND_DEPS="PM__COMMAND_DEPS"
	fi
	pm_check_dependencies warn "${COMMAND_DEPS[@]}" || true
}

init_check_branch() {
	if check_repo; then
		ds_switch_branch
	fi
}

init_check_symlink() {
	if [[ -L ${DS_COMMAND} ]]; then
		local DS_SYMLINK
		DS_SYMLINK=$(readlink -f "${DS_COMMAND}")
		if [[ ${SCRIPTNAME} != "${DS_SYMLINK}" ]]; then
			if check_repo; then
				if run_script 'question_prompt' "${PROMPT:-CLI}" N "${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} installation found at '${C["File"]-}${DS_SYMLINK}${NC-}' location. Would you like to run '${C["UserCommand"]-}${SCRIPTNAME}${NC-}' instead?"; then
					run_script 'symlink_ds'
					DS_COMMAND=$(command -v "${APPLICATION_COMMAND}" || true)
					DS_SYMLINK=$(readlink -f "${DS_COMMAND}")
				fi
			fi
			warn \
				"Attempting to run ${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} from '${C["RunningCommand"]-}${DS_SYMLINK}${NC-}' location."
			bash "${DS_SYMLINK}" -vyu
			bash "${DS_SYMLINK}" -vyi --config-show
			exec bash "${DS_SYMLINK}" "${ARGS[@]-}"
		fi
	fi
	# Create Symlink
	run_script 'symlink_ds'
}

init_check_update() {
	local Branch
	Branch="$(ds_branch)"
	if ds_branch_exists "${Branch}"; then
		if ds_update_available; then
			warn \
				"${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} [${C["Version"]-}${APPLICATION_VERSION}${NC-}]" \
				"An update to ${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} is available." \
				"Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -u${NC-}' to update to version '${C["Version"]-}$(ds_version "${Branch}")${NC-}'."
		else
			info \
				"${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} [${C["Version"]-}${APPLICATION_VERSION}${NC-}]"
		fi
	else
		local MainBranch="${APPLICATION_DEFAULT_BRANCH}"
		if ! ds_branch_exists "${MainBranch}"; then
			MainBranch="${APPLICATION_LEGACY_BRANCH}"
		fi
		warn \
			"${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} branch '${C["Branch"]-}${Branch}${NC-}' appears to no longer exist." \
			"${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} is currently on version '${C["Version"]-}$(ds_version)${NC-}'."
		if ! ds_branch_exists "${MainBranch}"; then
			error \
				"${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} does not appear to have a '${C["Branch"]-}${APPLICATION_DEFAULT_BRANCH}${NC-}' or '${C["Branch"]-}${APPLICATION_LEGACY_BRANCH}${NC-}' branch."
		else
			warn \
				"Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -u ${MainBranch}${NC-}' to update to the latest stable release '${C["Version"]-}$(ds_version "${MainBranch}")${NC-}'."
		fi
	fi
	Branch="$(templates_branch)"
	if templates_branch_exists "${Branch}"; then
		if templates_update_available; then
			warn \
				"${C["ApplicationName"]-}${TEMPLATES_NAME}${NC-} [${C["Version"]-}${TEMPLATES_VERSION}${NC-}]" \
				"An update to ${C["ApplicationName"]-}${TEMPLATES_NAME}${NC-} is available." \
				"Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -u${NC-}' to update to version '${C["Version"]-}$(templates_version "${Branch}")${NC-}'."
		else
			info \
				"${C["ApplicationName"]-}${TEMPLATES_NAME}${NC-} [${C["Version"]-}${TEMPLATES_VERSION}${NC-}]"
		fi
	else
		Branch="${TEMPLATES_DEFAULT_BRANCH}"
		warn \
			"${C["ApplicationName"]-}${TEMPLATES_NAME}${NC-} branch '${C["Branch"]-}${Branch}${NC-}' appears to no longer exist." \
			"${C["ApplicationName"]-}${TEMPLATES_NAME}${NC-} is currently on version '${C["Version"]-}$(templates_version)${NC-}'."
		if ! templates_branch_exists "${Branch}"; then
			error \
				"${C["ApplicationName"]-}${TEMPLATES_NAME}${NC-} does not appear to have a '${C["Branch"]-}${TEMPLATES_DEFAULT_BRANCH}${NC-}' branch."
		else
			warn \
				"Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -u ${Branch}${NC-}' to update to the latest stable release '${C["Version"]-}$(templates_version "${Branch}")${NC-}'."
		fi
	fi
}

init() {
	# Verify the running environment is compatible
	init_check_system
	# Verify the repo is cloned
	init_check_cloned
	# Verify the templates repo is cloned
	init_check_templates
	# Verify the terminal is writable
	init_check_tty
	# Verify the dependencies are installed
	init_check_dependencies
	# Verify we are on the correct branch
	init_check_branch
	# Verify the symlink is created
	init_check_symlink
	# Verify that we are on the latest version
	init_check_update
}

# Main Function
main() {
	init
	run_script 'apply_config'
	cmdline "${ARGS[@]-}"
}

main
