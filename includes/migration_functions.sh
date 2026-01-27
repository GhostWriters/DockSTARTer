#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

MigrateFilesAndFolders() {
	local -A MigrationFileMap=(
		["${SCRIPTPATH}/dockstarter.log"]="${APPLICATION_LOG}"
		["${APPLICATION_STATE_FOLDER}/fatal.log"]="${FATAL_LOG}"
		["${SCRIPTPATH}/fatal.log"]="${FATAL_LOG}"
	)

	local -A MigrationFolderMap=(
		["${APPLICATION_STATE_FOLDER}/.theme"]="${THEME_FOLDER}"
		["${APPLICATION_STATE_FOLDER}/.timestamps"]="${TIMESTAMPS_FOLDER}"
		["${APPLICATION_STATE_FOLDER}/.instances"]="${INSTANCES_FOLDER}"
	)

	for OldFile in "${!MigrationFileMap[@]}"; do
		local NewFile="${MigrationFileMap[${OldFile}]}"

		if [[ ! -f ${NewFile} && -f ${OldFile} ]]; then
			warn "Migrating '${C["File"]}${OldFile}${NC}' to '${C["File"]}${NewFile}${NC}'."
			RunAndLog warn "mv:warn" \
				warn "Failed to migrate '${C["File"]}${OldFile}${NC}'." \
				mv "${OldFile}" "${NewFile}" || true
		fi
	done

	for OldFolder in "${!MigrationFolderMap[@]}"; do
		local NewFolder="${MigrationFolderMap[${OldFolder}]}"

		if [[ ! -d ${NewFolder} && -d ${OldFolder} ]]; then
			warn "Migrating '${C["Folder"]}${OldFolder}${NC}' to '${C["Folder"]}${NewFolder}${NC}'."
			RunAndLog warn "mv:warn" \
				warn "Failed to migrate '${C["Folder"]}${OldFolder}${NC}'." \
				mv "${OldFolder}" "${NewFolder}" || true
		fi
	done
}
