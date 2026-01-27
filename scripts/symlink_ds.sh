#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

symlink_ds() {
	run_script 'set_permissions' "${SCRIPTNAME}"

	# The list of folders to try to create the symlink in
	local -a SymlinkFolders=(
		"/usr/bin"
		"/usr/local/bin"
		"${HOME}/bin"
		"${HOME}/.local/bin"
	)

	# Re-arrange the folders to the order they are listed in the PATH variable
	readarray -t SymlinkFolders < <(path_order "${SymlinkFolders[@]}")

	local FinalSymlinkFolder=''
	for Folder in "${SymlinkFolders[@]}"; do
		local SymlinkTarget="${Folder}/${APPLICATION_COMMAND}"
		if [[ -L ${SymlinkTarget} ]] && [[ ${SCRIPTNAME} != "$(readlink -f "${SymlinkTarget}")" ]]; then
			info "Attempting to remove '${C["File"]}${SymlinkTarget}${NC}' symlink."
			sudo rm -f "${SymlinkTarget}" &> /dev/null || true
		fi
		if [[ ! -L ${SymlinkTarget} ]]; then
			info "Creating '${C["File"]}${SymlinkTarget}${NC}' symbolic link for ${C["ApplicationName"]-}${APPLICATION_NAME}."
			mkdir -p "${Folder}" &> /dev/null || true
			sudo ln -s "${SCRIPTNAME}" "${SymlinkTarget}" &> /dev/null || true
		fi
		if [[ -L ${SymlinkTarget} ]]; then
			FinalSymlinkFolder="${Folder}"
			break
		fi
	done
	if [[ -n ${FinalSymlinkFolder} ]]; then
		if [[ ":${PATH}:" != *":${FinalSymlinkFolder}:"* ]]; then
			warn \
				"'${C["File"]}${FinalSymlinkFolder}${NC}' not found in '${C["Var"]}PATH${NC}'. Please add it to your '${C["Var"]}PATH${NC}' in order to use the '${C["UserCommand"]}${APPLICATION_COMMAND}${NC}' command alias."
		fi
	else
		fatal "Failed to create symlink."
	fi
}

path_order() {
	# Re-arrange the folders to the order they are listed in the PATH variable
	local -a FoldersArray=("$@")
	local -a PathArray
	readarray -d ':' -t PathArray <<< "${PATH}"
	for path_index in "${!PathArray[@]}"; do
		local PathFolder="${PathArray[path_index]}"
		local Folder
		for folder_index in "${!FoldersArray[@]}"; do
			Folder="${FoldersArray[folder_index]}"
			if [[ ${Folder} == "${PathFolder}" ]]; then
				unset 'FoldersArray[folder_index]'
				break
			fi
		done
		if [[ ${Folder} != "${PathFolder}" ]]; then
			unset 'PathArray[path_index]'
		fi
	done
	printf '%s\n' "${PathArray[@]}" "${FoldersArray[@]}"
}

test_symlink_ds() {
	run_script 'symlink_ds'
}
