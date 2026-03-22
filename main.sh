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

declare -Ag C DC

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
for XDG_FOLDER in "${XDG_DATA_HOME}" "${XDG_CONFIG_HOME}" "${XDG_CONFIG_HOME}/${APPLICATION_NAME,,}" "${XDG_CACHE_HOME}" "${XDG_STATE_HOME}" "${XDG_STATE_HOME}/${APPLICATION_NAME,,}"; do
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
declare -rgx FATAL_LOG="${XDG_STATE_HOME}/${APPLICATION_NAME,,}/${APPLICATION_NAME,,}.fatal.log"

declare -rgx APPLICATION_UPDATE_RECORD="${XDG_STATE_HOME}/${APPLICATION_NAME,,}/${APPLICATION_NAME,,}.updated"
declare -Agx ColorCodes=(
	[black]=K [red]=R [green]=G [yellow]=Y
	[blue]=B [magenta]=M [cyan]=C [white]=W
)

resolve_styles() {
	local style_map_name="$1"
	local -n style_map="$1"
	local val="$2"
	local last_val=""
	local -i MaxResolves=100

	local sem_p="${3-}" sem_s="${4-}"
	local dir_p="${5-}" dir_s="${6-}"

	while [[ ${MaxResolves} -gt 0 ]]; do
		local regex p_tag content s_tag full_match
		if [[ -n ${sem_p-} ]]; then
			# Custom syntax
			local esc_sem_p="${sem_p//\[/\\\[}"
			esc_sem_p="${esc_sem_p//\|/\\|}"
			esc_sem_p="${esc_sem_p//\{/\\\{}"
			local esc_sem_s="${sem_s//\]/\\\]}"
			esc_sem_s="${esc_sem_s//\|/\\|}"
			esc_sem_s="${esc_sem_s//\}/\\\}}"
			local esc_dir_p="${dir_p//\[/\\\[}"
			esc_dir_p="${esc_dir_p//\|/\\|}"
			esc_dir_p="${esc_dir_p//\{/\\\{}"
			local esc_dir_s="${dir_s//\]/\\\]}"
			esc_dir_s="${esc_dir_s//\|/\\|}"
			esc_dir_s="${esc_dir_s//\}/\\\}}"
			regex="(${esc_sem_p}|${esc_dir_p})([^]|}]+)(${esc_sem_s}|${esc_dir_s})"

			[[ ${val} =~ ${regex} ]] || break
			full_match="${BASH_REMATCH[0]}"
			p_tag="${BASH_REMATCH[1]}"
			content="${BASH_REMATCH[2]}"
			s_tag="${BASH_REMATCH[3]}"

			# Ensure matching prefix/suffix types
			if [[ ${p_tag} == "${sem_p}" && ${s_tag} == "${sem_s}" ]]; then
				if [[ ${content} == *":"* ]]; then
					local base="${content%%:*}"
					local mod="${content#*:}"
					val="${val//"${full_match}"/"${sem_p}${base}${sem_s}${dir_p}${mod}${dir_s}"}"
					continue
				fi
			elif [[ ${p_tag} != "${dir_p}" || ${s_tag} != "${dir_s}" ]]; then
				# Mismatched tags
				break
			fi
		else
			# Default syntax: {{|...|}} or {{[...]}}
			regex='\{\{(\[|\|)([^]|}]+)(\]|\|)\}\}'
			[[ ${val} =~ ${regex} ]] || break
			full_match="${BASH_REMATCH[0]}"
			local type="${BASH_REMATCH[1]}"
			content="${BASH_REMATCH[2]}"
			local end_type="${BASH_REMATCH[3]}"

			# Ensure matching start/end types (| with | and [ with ])
			if [[ ${type} == "|" && ${end_type} == "|" ]]; then
				p_tag="${type}"
				s_tag="${end_type}"
				if [[ ${content} == *":"* ]]; then
					local base="${content%%:*}"
					local mod="${content#*:}"
					val="${val//"${full_match}"/"{{|${base}|}}{{[${mod}]}}"}"
					continue
				fi
			elif [[ ${type} == "[" && ${end_type} == "]" ]]; then
				p_tag="${type}"
				s_tag="${end_type}"
			else
				break
			fi
		fi

		[[ ${val} == "${last_val}" ]] && break
		MaxResolves=$((MaxResolves - 1))
		last_val="${val}"

		local replacement=""
		if [[ ${p_tag} == "|" || ${p_tag} == "${sem_p-}" ]]; then
			# Semantic tag: lookup in map (Raw key)
			if [[ -v style_map["${content}"] ]]; then
				replacement="${style_map["${content}"]}"
			fi
		elif [[ ${p_tag} == "[" || ${p_tag} == "${dir_p-}" ]]; then
			# Direct tag: Dynamic parsing for {{[...]}} or custom direct tags
			local fg="" bg="" flags="" resolved=""
			if [[ ${content} == "-" ]]; then
				# Reset tag
				if [[ ${style_map_name} == "DC" ]]; then
					resolved='\Zn'
				else
					resolved="${S["-"]}"
				fi
			else
				# Parse [fg:bg:flags]
				if [[ ${content} == *":"* ]]; then
					fg="${content%%:*}"
					local rest="${content#*:}"
					if [[ ${rest} == *":"* ]]; then
						bg="${rest%%:*}"
						flags="${rest#*:}"
					else
						bg="${rest}"
						flags=""
					fi
				else
					# Single part tag: is it a color name or a code or a flag?
					local content_lower="${content,,}"
					local content_upper="${content^^}"
					if [[ -v ColorCodes[${content_lower}] ]]; then
						fg="${content_lower}"
					elif [[ -v F[${content_upper}] ]]; then
						fg="${content_upper}"
					else
						flags="${content}"
					fi
				fi

				# Resolve FG, BG, Flags
				local -A ZC=([K]=0 [R]=1 [G]=2 [Y]=3 [B]=4 [M]=5 [C]=6 [W]=7)
				if [[ -n ${fg} ]]; then
					local fg_code="${ColorCodes[${fg,,}]-${fg^^}}"
					if [[ ${style_map_name} == "DC" ]]; then
						resolved+="\Z${ZC[${fg_code}]-0}"
					elif [[ -v F[${fg_code}] ]]; then
						resolved+="${F[${fg_code}]}"
					fi
				fi
				if [[ -n ${bg} ]]; then
					local bg_code="${ColorCodes[${bg,,}]-${bg^^}}"
					if [[ ${style_map_name} == "DC" ]]; then
						resolved+="\z${ZC[${bg_code}]-0}"
					elif [[ -v B[${bg_code}] ]]; then
						resolved+="${B[${bg_code}]}"
					fi
				fi
				if [[ -n ${flags} ]]; then
					local -i k
					for ((k = 0; k < ${#flags}; k++)); do
						local char="${flags:k:1}"
						if [[ ${style_map_name} == "DC" ]]; then
							case ${char} in
								B) resolved+='\Zb' ;;
								D) resolved+='\Zd' ;;
								L) resolved+='\Zl' ;;
								R) resolved+='\Zr' ;;
								U) resolved+='\Zu' ;;
							esac
						elif [[ -v S[${char}] ]]; then
							resolved+="${S[${char}]}"
						fi
					done
				fi
			fi
			replacement="${resolved}"
		fi
		val="${val//"${full_match}"/"${replacement}"}"
	done
	printf '%s\n' "${val}"
}

resolve_strings() {
	local array_name="$1"
	shift

	# Process every argument (and every line within those arguments), or read from STDIN if no arguments
	if [[ $# -gt 0 ]]; then
		printf '%s\n' "$@"
	else
		cat
	fi | while IFS= read -r line || [[ -n ${line} ]]; do
		if [[ -t 1 ]]; then
			# Call the single-string resolver for each line
			resolve_styles "$array_name" "$line"
		else
			# Call the single-string stripper for each line
			strip_styles "$line"
		fi
	done
}

strip_styles() {
	local val="${1:-}"
	local extglob_on=0
	shopt -q extglob || extglob_on=$?

	shopt -s extglob
	# Remove {{|...|}} and {{[...]}}
	val="${val//\{\{\|*([!|])|\}\}/}"
	val="${val//\{\{\[*([!\]])\]\}\}/}"

	# Only turn extglob off if it was off before
	[[ ${extglob_on} -ne 0 ]] && shopt -u extglob || true

	printf '%s\n' "${val}"
}

# shellcheck disable=SC2120
strip_strings() {
	# Process every argument (and every line within those arguments), or read from STDIN if no arguments
	if [[ $# -gt 0 ]]; then
		printf '%s\n' "$@"
	else
		cat
	fi | while IFS= read -r line || [[ -n ${line} ]]; do
		# Call the single-string stripper for each line
		strip_styles "$line"
	done
}

# Terminal Colors
declare -Agr B=( # Background
	[B]=$(tput setab 4 2> /dev/null || echo -e "\e[44m")   # Blue
	[C]=$(tput setab 6 2> /dev/null || echo -e "\e[46m")   # Cyan
	[G]=$(tput setab 2 2> /dev/null || echo -e "\e[42m")   # Green
	[K]=$(tput setab 0 2> /dev/null || echo -e "\e[40m")   # Black
	[M]=$(tput setab 5 2> /dev/null || echo -e "\e[45m")   # Magenta
	[R]=$(tput setab 1 2> /dev/null || echo -e "\e[41m")   # Red
	[W]=$(tput setab 7 2> /dev/null || echo -e "\e[47m")   # White
	[Y]=$(tput setab 3 2> /dev/null || echo -e "\e[43m")   # Yellow
	["-"]=$(tput setab 9 2> /dev/null || echo -e "\e[49m") # Default
)
declare -Agr F=( # Foreground
	[B]=$(tput setaf 4 2> /dev/null || echo -e "\e[34m")   # Blue
	[C]=$(tput setaf 6 2> /dev/null || echo -e "\e[36m")   # Cyan
	[G]=$(tput setaf 2 2> /dev/null || echo -e "\e[32m")   # Green
	[K]=$(tput setaf 0 2> /dev/null || echo -e "\e[30m")   # Black
	[M]=$(tput setaf 5 2> /dev/null || echo -e "\e[35m")   # Magenta
	[R]=$(tput setaf 1 2> /dev/null || echo -e "\e[31m")   # Red
	[W]=$(tput setaf 7 2> /dev/null || echo -e "\e[37m")   # White
	[Y]=$(tput setaf 3 2> /dev/null || echo -e "\e[33m")   # Yellow
	["-"]=$(tput setaf 9 2> /dev/null || echo -e "\e[39m") # Default
)
declare -Agr S=(
	[BS]=$(tput cup 1000 0 2> /dev/null || true)       # Bottom of screen
	["-"]=$(tput sgr0 2> /dev/null || echo -e "\e[0m") # No Color
	[D]=$(tput dim 2> /dev/null || echo -e "\e[2m")    # Dim
	[d]=$(tput sgr0 2> /dev/null || echo -e "\e[0m")   # No Dim
	[L]=$(tput blink 2> /dev/null || echo -e "\e[5m")  # Blink
	[l]=$(tput sgr0 2> /dev/null || echo -e "\e[0m")   # No Blink
	[B]=$(tput bold 2> /dev/null || echo -e "\e[1m")   # Bold
	[b]=$(tput sgr0 2> /dev/null || echo -e "\e[0m")   # No Bold
	[U]=$(tput smul 2> /dev/null || echo -e "\e[4m")   # Underline
	[u]=$(tput rmul 2> /dev/null || echo -e "\e[24m")  # No Underline
	[R]=$(tput rev 2> /dev/null || echo -e "\e[7m")    # Reverse Video
	[r]=$(tput sgr0 2> /dev/null || echo -e "\e[0m")   # No Reverse Video
)

DM="${S[D]}"
readonly DM
export DM
BL="${S[L]}"
readonly BL
export BL
BD="${S[B]}"
readonly BD
export BD
UL="${S[U]}"
readonly UL
export UL
NC="${S["-"]}"
readonly NC
export NC
BS="${S[BS]}"
readonly BS
export BS

declare -Ag C=( # Pre-defined colors
	[Timestamp]="{{[::D]}}"
	[Trace]="{{[blue]}}"
	[Debug]="{{[blue]}}"
	[Info]="{{[blue]}}"
	[Notice]="{{[green]}}"
	[Warn]="{{[yellow]}}"
	[Error]="{{[red]}}"
	[Fatal]="{{[white]}}{{[:red]}}"

	[FatalFooter]="{{[-]}}"
	[TraceHeader]="{{[red]}}"
	[TraceFooter]="{{[red]}}"
	[TraceFrameNumber]="{{[red]}}"
	[TraceFrameLines]="{{[red]}}"
	[TraceSourceFile]="{{[cyan]}}{{[::B]}}"
	[TraceLineNumber]="{{[yellow]}}{{[::B]}}"
	[TraceFunction]="{{[green]}}{{[::B]}}"
	[TraceCmd]="{{[green]}}{{[::B]}}"
	[TraceCmdArgs]="{{[green]}}"

	[UnitTestPass]="{{[green]}}"
	[UnitTestFail]="{{[red]}}"
	[UnitTestFailArrow]="{{[red]}}"

	[App]="{{[cyan]}}"
	[ApplicationName]="{{[cyan]}}{{[::B]}}"
	[Branch]="{{[cyan]}}"
	[FailingCommand]="{{[red]}}"
	[File]="{{[cyan]}}{{[::B]}}"
	[Folder]="{{[cyan]}}{{[::B]}}"
	[Program]="{{[cyan]}}"
	[RunningCommand]="{{[green]}}{{[::B]}}"
	[Theme]="{{[cyan]}}"
	[Update]="{{[green]}}"
	[User]="{{[cyan]}}"
	[URL]="{{[cyan]}}{{[::U]}}"
	[UserCommand]="{{[yellow]}}{{[::B]}}"
	[UserCommandError]="{{[red]}}{{[::U]}}"
	[UserCommandErrorMarker]="{{[red]}}"
	[Var]="{{[magenta]}}"
	[Version]="{{[cyan]}}"
	[Yes]="{{[green]}}"
	[No]="{{[red]}}"

	[ButtonName]="{{[cyan]}}"

	[UsageCommand]="{{[yellow]}}{{[::B]}}"
	[UsageOption]="{{[yellow]}}"
	[UsageApp]="{{[cyan]}}"
	[UsageBranch]="{{[cyan]}}"
	[UsageFile]="{{[cyan]}}{{[::B]}}"
	[UsagePage]="{{[cyan]}}{{[::B]}}"
	[UsageTheme]="{{[cyan]}}"
	[UsageVar]="{{[magenta]}}"
)

for Style in "${!C[@]}"; do
	C["$Style"]="$(resolve_styles C "${C["$Style"]}")"
done
# C must not be readonly so that dynamic styles can be cached!

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

indent_string_pipe() {
	local -i IndentSize=${1}
	indent_text ${IndentSize} "$(cat -)"
}

get_system_info() {
	local -a Output=()

	Output+=(
		"{{|ApplicationName|}}${APPLICATION_NAME-}{{[-]}} [{{|Version|}}${APPLICATION_VERSION-}{{[-]}}]"
		"{{|ApplicationName|}}${TEMPLATES_NAME-}{{[-]}} [{{|Version|}}${TEMPLATES_VERSION-}{{[-]}}]"
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

	# shellcheck disable=SC2016 # Expressions don't expand in single quotes, use double quotes for that.
	Output+=(
		""
		'{{|RunningCommand|}}echo ${BASH_VERSION}{{[-]}}:'
		"${BASH_VERSION-}"
	)

	[[ -f /etc/os-release ]] &&
		Output+=(
			""
			"{{|RunningCommand|}}cat /etc/os-release{{[-]}}:"
			"$(PrefixFileLines '  ' /etc/os-release)"
		)

	printf '%s\n' "${Output[@]}"
}

# Log Functions
MKTEMP_LOG=$(mktemp -t "${APPLICATION_NAME,,}.log.XXXXXXXXXX") || resolve_strings C "Failed to create temporary log file." "Failing command: {{|FailingCommand|}}mktemp -t \"${APPLICATION_NAME,,}.log.XXXXXXXXXX\""
readonly MKTEMP_LOG
echo "${APPLICATION_NAME} Log" > "${MKTEMP_LOG}"

log() {
	local LogToTerminal=${1-}
	local Message=${2-}
	local StrippedMessage
	StrippedMessage=$(strip_styles "${Message-}")
	if [[ ${LogToTerminal} == true ]]; then
		if [[ -t 2 ]]; then
			# Stderr is a TTY, output with color
			resolve_strings C "${Message}" >&2
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
		printf "{{[-]}}{{|Timestamp|}}${Timestamp}{{[-]}} ${LogLevelTag} %s{{[-]}}\n" "${line}"
	done <<< "${LogMessage}"
}
trace() { log "${TRACE-}" "$(timestamped_log "{{|Trace|}}[TRACE ]{{[-]}}" "$@")"; }
debug() { log "${DEBUG-}" "$(timestamped_log "{{|Debug|}}[DEBUG ]{{[-]}}" "$@")"; }
info() { log "${VERBOSE-}" "$(timestamped_log "{{|Info|}}[INFO  ]{{[-]}}" "$@")"; }
notice() { log true "$(timestamped_log "{{|Notice|}}[NOTICE]{{[-]}}" "$@")"; }
warn() { log true "$(timestamped_log "{{|Warn|}}[WARN  ]{{[-]}}" "$@")"; }
error() { log true "$(timestamped_log "{{|Error|}}[ERROR ]{{[-]}}" "$@")"; }
fatal_notrace() {
	local LogMessage
	LogMessage=$(timestamped_log "{{|Fatal|}}[FATAL ]{{[-]}}" "$@")
	log true "${LogMessage}"
	LogMessage=$(strip_styles "${LogMessage-}")
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
			line="${BASH_LINENO[i-1]:-0}"
		fi

		local prefix=""
		local arrowIndent="${indent}"
		if ((i < StackSize - 1)); then
			prefix="{{|TraceFrameLines|}}└>{{[-]}}"
			if [[ ${#indent} -ge 2 ]]; then
				arrowIndent="${indent%  }"
			fi
		fi

		# Format: "Num: [Indent]Arrow File:Line (Function)"
		local StackLineFormat="{{|TraceFrameNumber|}}%${FrameNumberLength}d{{[-]}}: ${arrowIndent}${prefix}{{|TraceSourceFile|}}%s{{[-]}}:{{|TraceLineNumber|}}%d{{[-]}} ({{|TraceFunction|}}%s{{[-]}})"
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

			local FrameCmdPrefix="{{|TraceFrameLines|}}│{{[-]}}"
			local FrameArgPrefix="{{|TraceFrameLines|}}│{{[-]}}"

			local cmdString="{{|TraceCmd|}}${cmd}{{[-]}}"
			local -a cmdArray=()
			cmdArray+=("${FrameCmdPrefix}${cmdString}")

			if [[ CmdArgCount -ne 0 ]]; then
				for ((j = CurrentArg + CmdArgCount - 1; j >= CurrentArg; j--)); do
					local cmdArgString="${BASH_ARGV[$j]}"
					#cmdArgString="$(strip_styles "${cmdArgString}")"
					cmdArgString="${cmdArgString//\\/\\\\}"
					cmdArgString="{{[-]}}«{{|TraceCmdArgs|}}${cmdArgString}{{[-]}}»"
					while read -r cmdLine; do
						cmdArray+=(
							"${FrameArgPrefix}{{|TraceCmdArgs|}}${cmdLine}"
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
		"{{|TraceHeader|}}### BEGIN SYSTEM INFORMATION AND STACK TRACE ###" \
		"$(indent_text 2 "${Stack[@]}")" \
		"{{|TraceFooter|}}### END SYSTEM INFORMATION AND STACK TRACE ###" \
		"" \
		"$@" \
		"" \
		"{{|FatalFooter|}}Please let the dev know of this error." \
		"{{|FatalFooter|}}It has been written to '{{|File|}}${FATAL_LOG}{{|FatalFooter|}}'," \
		"{{|FatalFooter|}}and appended to '{{|File|}}${APPLICATION_LOG}{{|FatalFooter|}}'."
}

PrefixFileLines() {
	local Prefix="${1}"
	local FileName="${2}"
	local line
	while IFS= read -r line || [[ -n ${line} ]]; do
		printf '%s%s\n' "${Prefix}" "${line}"
	done < "${FileName}"
}

RunAndLog() {
	# RunAndLog [RunningNoticeType] [Prefix:[OutputNoticeType]] [ErrorNoticeType] [ErrorMessage] [Command]
	# To skip an optional argument, pass an empty string
	local -l RunningNoticeType=${1-}
	local -l OutputNoticeType=${2-}
	local -l ErrorNoticeType=${3-}
	local ErrorMessage=${4-}
	shift 4
	local -a Command=("${@}")

	local NoticeTypes_Regex='info|notice|warn|error|debug|trace'

	local Prefix=''
	if [[ ${OutputNoticeType} == *:* ]]; then
		Prefix="${OutputNoticeType%%:*}:"
		OutputNoticeType=${OutputNoticeType#"${Prefix}"}
		Prefix="{{|RunningCommand|}}${Prefix}{{[-]}} "
	fi

	local OutputFile

	local CommandText
	CommandText="$(printf '%q ' "${Command[@]}" | xargs 2> /dev/null)"

	# If the running notice type is set, log the command being run
	[[ -n ${RunningNoticeType-} ]] &&
		"${RunningNoticeType}" \
			"Running: {{|RunningCommand|}}${CommandText}"

	local ErrToNull=false
	local OutToNull=false
	if [[ ${OutputNoticeType-} =~ errtonull|bothtonull ]]; then
		ErrToNull=true
	fi
	if [[ ${OutputNoticeType-} =~ outtonull|bothtonull ]]; then
		OutToNull=true
	fi
	if [[ ${ErrToNull} != true || ${OutToNull} != true ]] && [[ ${OutputNoticeType-} =~ ${NoticeTypes_Regex} ]]; then
		# If the output notice type is set, save the output to a file
		OutputFile=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.RunAndLogOutputFile.XXXXXXXXXX")
	fi
	local -i result=0
	if [[ ${ErrToNull} == true && ${OutToNull} == true ]]; then
		# Both stdout and stderr are redirected to /dev/null
		"${Command[@]}" &> /dev/null || result=$?
	elif [[ ${ErrToNull} == true && -n ${OutputFile-} ]]; then
		# stderr redircted to /dev/null, stdout redirected to output file
		"${Command[@]}" > "${OutputFile}" 2> /dev/null || result=$?
	elif [[ ${OutToNull} == true && -n ${OutputFile-} ]]; then
		# stdout redircted to /dev/null, stderr redirected to output file
		"${Command[@]}" 2> "${OutputFile}" > /dev/null || result=$?
	elif [[ -n ${OutputFile-} ]]; then
		# Both stdout and stderr redirected to output file
		"${Command[@]}" &> "${OutputFile}" || result=$?
	else
		# No redirection
		"${Command[@]}" || result=$?
	fi

	if [[ -n ${OutputFile-} && -s ${OutputFile} ]]; then
		local line
		while IFS= read -r line || [[ -n ${line} ]]; do
			"${OutputNoticeType}" "${Prefix}${line}"
		done < "${OutputFile}"
		rm -f "${OutputFile}"
	fi

	[[ ${result} -eq 0 ]] && return

	if [[ -n ${ErrorNoticeType-} ]]; then
		# If the error notice type is set, log the error
		${ErrorNoticeType} \
			"${ErrorMessage}" \
			"Failing command: {{|FailingCommand|}}${CommandText}"
	fi
	return ${result}
}

[[ -f "${SCRIPTPATH}/includes/misc_functions.sh" ]] && source "${SCRIPTPATH}/includes/misc_functions.sh"
[[ -f "${SCRIPTPATH}/includes/global_variables.sh" ]] && source "${SCRIPTPATH}/includes/global_variables.sh"
[[ -f "${SCRIPTPATH}/includes/migration_functions.sh" ]] && source "${SCRIPTPATH}/includes/migration_functions.sh"
if declare -F MigrateFilesAndFolders > /dev/null; then
	MigrateFilesAndFolders
fi
[[ -f "${SCRIPTPATH}/includes/pm_variables.sh" ]] && source "${SCRIPTPATH}/includes/pm_variables.sh"
[[ -f "${SCRIPTPATH}/includes/run_script.sh" ]] && source "${SCRIPTPATH}/includes/run_script.sh"
[[ -f "${SCRIPTPATH}/includes/dialog_functions.sh" ]] && source "${SCRIPTPATH}/includes/dialog_functions.sh"
[[ -f "${SCRIPTPATH}/includes/ds_functions.sh" ]] && source "${SCRIPTPATH}/includes/ds_functions.sh"
[[ -f "${SCRIPTPATH}/includes/test_functions.sh" ]] && source "${SCRIPTPATH}/includes/test_functions.sh"
[[ -f "${SCRIPTPATH}/includes/usage.sh" ]] && source "${SCRIPTPATH}/includes/usage.sh"
[[ -f "${SCRIPTPATH}/includes/cmdline.sh" ]] && source "${SCRIPTPATH}/includes/cmdline.sh"

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
	if RunAndLog info "git:info" "" "" git -C "${SCRIPTPATH}" rev-parse --is-inside-work-tree; then
		if [[ -d ${SCRIPTPATH}/includes ]] && [[ -d ${SCRIPTPATH}/scripts ]]; then
			return
		else
			return 1
		fi
	else
		return 1
	fi
}

# Check if the templates repo exists relative to the ${TEMPLATES_PARENT_FOLDER}
check_templates_repo() {
	if RunAndLog info "git:info" "" "" git -C "${TEMPLATES_PARENT_FOLDER}" rev-parse --is-inside-work-tree; then
		return
	else
		return 1
	fi
}
# Check if running as root
check_root() {
	if [[ ${DETECTED_PUID} == "0" ]] || [[ ${DETECTED_HOMEDIR} == "/root" ]]; then
		fatal_notrace \
			"Running as '{{|User|}}root{{[-]}}' is not supported." \
			"Please run as a standard user."
	fi
}

# Check if running with sudo
check_sudo() {
	if [[ ${EUID} -eq 0 ]]; then
		fatal_notrace \
			"Running with '{{|UserCommand|}}sudo{{[-]}}' is not supported." \
			"Commands requiring '{{|UserCommand|}}sudo{{[-]}}' will prompt automatically when required."
	fi
}
clone_repo() {
	warn \
		"Attempting to clone {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} repo to '{{|Folder|}}${DETECTED_HOMEDIR}/${APPLICATION_FOLDER_NAME_DEFAULT}{{[-]}}' location."
	RunAndLog notice "git:notice" \
		fatal "Failed to clone {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} repo." \
		git clone -b "${APPLICATION_DEFAULT_BRANCH}" "${APPLICATION_REPO}" "${DETECTED_HOMEDIR}/${APPLICATION_FOLDER_NAME_DEFAULT}"
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
		"Attempting to clone {{|ApplicationName|}}${TEMPLATES_NAME}{{[-]}} repo to '{{|Folder|}}${TEMPLATES_PARENT_FOLDER}{{[-]}}' location."
	if [[ -d ${TEMPLATES_PARENT_FOLDER?} ]]; then
		RunAndLog notice "rm:notice" \
			fatal "Failed to remove ${TEMPLATES_PARENT_FOLDER?}." \
			sudo rm -rf "${TEMPLATES_PARENT_FOLDER?}"
	fi
	RunAndLog notice "git:notice" \
		fatal "Failed to clone {{|ApplicationName|}}${TEMPLATES_NAME}{{[-]}} repo." \
		git clone -b "${TEMPLATES_DEFAULT_BRANCH}" "${TEMPLATES_REPO}" "${TEMPLATES_PARENT_FOLDER}"
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
		resolve_strings C \
			"{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} did not finish running successfully." \
			"Check logs in '{{|File|}}${APPLICATION_LOG}{{[-]}}'."
	fi
	if [[ ${PROMPT:-CLI} == "GUI" ]]; then
		# Try to restore the terminal to a working state
		stty cooked echo
		# Move the cursor to the bottom of the screen
		echo -n "${S[BS]}"
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
					"{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} requires a writable TTY."
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
				if run_script 'question_prompt' "${PROMPT:-CLI}" N "{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} installation found at '{{|File|}}${DS_SYMLINK}{{[-]}}' location. Would you like to run '{{|UserCommand|}}${SCRIPTNAME}{{[-]}}' instead?"; then
					run_script 'symlink_ds'
					DS_COMMAND=$(command -v "${APPLICATION_COMMAND}" || true)
					DS_SYMLINK=$(readlink -f "${DS_COMMAND}")
				fi
			fi
			warn \
				"Attempting to run {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} from '{{|RunningCommand|}}${DS_SYMLINK}{{[-]}}' location."
			bash "${DS_SYMLINK}" -vyu
			bash "${DS_SYMLINK}" -vyi --config-show
			exec bash "${DS_SYMLINK}" "${ARGS[@]-}"
		fi
	fi
	# Create Symlink
	run_script 'symlink_ds'
}

init_check_update() {
	# Only check for updates once per 24 hours, as it can be quite slow.
	[ -n "$(find "${APPLICATION_UPDATE_RECORD}" -mtime -1 2>/dev/null)" ] && return
	local Branch
	Branch="$(ds_branch)"
	local TargetBranch="${Branch}"
	if ds_tag_exists "${Branch}"; then
		TargetBranch="$(ds_best_branch)"
	fi
	if ds_ref_exists "${Branch}"; then
		if ds_update_available "${Branch}" "${TargetBranch}"; then
			warn \
				"{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} [{{|Version|}}${APPLICATION_VERSION}{{[-]}}]" \
				"An update to {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} is available." \
				"Run '{{|UserCommand|}}${APPLICATION_COMMAND} -u{{[-]}}' to update to version '{{|Version|}}$(ds_version "${TargetBranch}"){{[-]}}'."
		else
			info \
				"{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} [{{|Version|}}${APPLICATION_VERSION}{{[-]}}]"
		fi
	else
		local MainBranch="${APPLICATION_DEFAULT_BRANCH}"
		if ! ds_branch_exists "${MainBranch}"; then
			MainBranch="${APPLICATION_LEGACY_BRANCH}"
		fi
		warn \
			"{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} branch '{{|Branch|}}${Branch}{{[-]}}' appears to no longer exist." \
			"{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} is currently on version '{{|Version|}}$(ds_version){{[-]}}'."
		if ! ds_branch_exists "${MainBranch}"; then
			error \
				"{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} does not appear to have a '{{|Branch|}}${APPLICATION_DEFAULT_BRANCH}{{[-]}}' or '{{|Branch|}}${APPLICATION_LEGACY_BRANCH}{{[-]}}' branch."
		else
			warn \
				"Run '{{|UserCommand|}}${APPLICATION_COMMAND} -u ${MainBranch}{{[-]}}' to update to the latest stable release '{{|Version|}}$(ds_version "${MainBranch}"){{[-]}}'."
		fi
	fi
	Branch="$(templates_branch)"
	local TargetBranch="${Branch}"
	if templates_tag_exists "${Branch}"; then
		TargetBranch="$(templates_best_branch)"
	fi
	if templates_ref_exists "${Branch}"; then
		if templates_update_available "${Branch}" "${TargetBranch}"; then
			warn \
				"{{|ApplicationName|}}${TEMPLATES_NAME}{{[-]}} [{{|Version|}}${TEMPLATES_VERSION}{{[-]}}]" \
				"An update to {{|ApplicationName|}}${TEMPLATES_NAME}{{[-]}} is available." \
				"Run '{{|UserCommand|}}${APPLICATION_COMMAND} -u{{[-]}}' to update to version '{{|Version|}}$(templates_version "${TargetBranch}"){{[-]}}'."
		else
			info \
				"{{|ApplicationName|}}${TEMPLATES_NAME}{{[-]}} [{{|Version|}}${TEMPLATES_VERSION}{{[-]}}]"
		fi
	else
		Branch="${TEMPLATES_DEFAULT_BRANCH}"
		warn \
			"{{|ApplicationName|}}${TEMPLATES_NAME}{{[-]}} branch '{{|Branch|}}${Branch}{{[-]}}' appears to no longer exist." \
			"{{|ApplicationName|}}${TEMPLATES_NAME}{{[-]}} is currently on version '{{|Version|}}$(templates_version){{[-]}}'."
		if ! templates_branch_exists "${Branch}"; then
			error \
				"{{|ApplicationName|}}${TEMPLATES_NAME}{{[-]}} does not appear to have a '{{|Branch|}}${TEMPLATES_DEFAULT_BRANCH}{{[-]}}' branch."
		else
			warn \
				"Run '{{|UserCommand|}}${APPLICATION_COMMAND} -u ${Branch}{{[-]}}' to update to the latest stable release '{{|Version|}}$(templates_version "${Branch}"){{[-]}}'."
		fi
	fi
	touch "${APPLICATION_UPDATE_RECORD}"
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
