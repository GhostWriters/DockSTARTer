#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_update() {
	#if ! run_script 'needs_env_update'; then
	#    # Env files have already been updated, nothing to do
	#    notice "Environment variable files already updated."
	#    return
	#fi
	if ! [[ -d ${COMPOSE_FOLDER} ]]; then
		notice "Creating folder '{{|Folder|}}${COMPOSE_FOLDER}{{[-]}}'."
		mkdir -p "${COMPOSE_FOLDER}" ||
			fatal \
				"Failed to create folder." \
				"Failing command: {{|FailingCommand|}}mkdir -p \"${COMPOSE_FOLDER}\""
	fi

	notice "Updating environment variable files."

	local -al applist
	readarray -t applist < <(
		run_script 'app_list_hasvarfile'
	)
	for appname in "${applist[@]}"; do
		if ! run_script 'app_is_referenced' "${appname}"; then
			# Delete every existing ".env.app.*" file belonging to this app,
			# not just the plain one -- a multi-service app can have several
			# (see appvars_filelist_into).
			local -a AppFiles
			run_script 'appvars_filelist_into' AppFiles "${appname}"
			local AppFileName
			for AppFileName in "${AppFiles[@]}"; do
				local AppEnvFile="${COMPOSE_FOLDER}/${AppFileName}"
				run_script 'set_permissions' "${AppEnvFile}"
				notice "Deleting '{{|File|}}${AppEnvFile}{{[-]}}'."
				rm -f "${AppEnvFile}" ||
					warn \
						"Failed to remove '{{|File|}}${AppEnvFile}{{[-]}}'." \
						"Failing command: {{|FailingCommand|}}rm -f \"${AppEnvFile}\""
			done
		fi
	done

	readarray -t applist < <(
		run_script 'app_list_referenced'
	)
	# Format the global .env file
	if ! run_script 'needs_env_update' "${COMPOSE_ENV}"; then
		info "File '{{|File|}}${COMPOSE_ENV}{{[-]}}' already updated."
	else
		notice "Updating '{{|File|}}${COMPOSE_ENV}{{[-]}}'."
		local ENV_LINES_FILE
		ENV_LINES_FILE=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.ENV_LINES_FILE.XXXXXXXXXX")
		run_script 'appvars_lines' "" > "${ENV_LINES_FILE}"

		local -a UPDATED_ENV_LINES=()
		run_script 'env_format_lines_into_array' UPDATED_ENV_LINES "${ENV_LINES_FILE}" "${COMPOSE_ENV_DEFAULT_FILE}" "" "${COMPOSE_ENV}"

		if [[ -n ${applist[*]-} ]]; then
			for appname in "${applist[@]}"; do
				local APP_DEFAULT_GLOBAL_ENV_FILE=""
				local -a UPDATED_APP_ENV_LINES=()
				if ! run_script 'app_is_user_defined' "${appname}"; then
					run_script 'app_instance_file_into' APP_DEFAULT_GLOBAL_ENV_FILE "${appname}" ".env"
				fi
				run_script 'appvars_lines' "${appname}" > "${ENV_LINES_FILE}"
				if ((${#UPDATED_ENV_LINES[@]} > 0)); then
					UPDATED_ENV_LINES+=("")
				fi
				local -a NewLines
				run_script 'env_format_lines_into_array' NewLines "${ENV_LINES_FILE}" "${APP_DEFAULT_GLOBAL_ENV_FILE}" "${appname}"
				UPDATED_ENV_LINES+=("${NewLines[@]-}")
			done
		fi
		RunAndLog "" "rm:notice" \
			warn "Failed to remove temporary '{{|File|}}.env{{[-]}}' update file." \
			rm -f "${ENV_LINES_FILE}"

		local MKTEMP_ENV_UPDATED
		MKTEMP_ENV_UPDATED=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_ENV_UPDATED.XXXXXXXXXX") ||
			fatal \
				"Failed to create temporary update '{{|File|}}.env{{[-]}}' file." \
				"Failing command: {{|FailingCommand|}}mktemp -t \"${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_ENV_UPDATED.XXXXXXXXXX\""
		printf '%s\n' "${UPDATED_ENV_LINES[@]}" > "${MKTEMP_ENV_UPDATED}" ||
			fatal \
				"Failed to write temporary '{{|File|}}.env{{[-]}}' update file."
		if [[ ! -f ${COMPOSE_ENV} ]] || ! cmp -s "${MKTEMP_ENV_UPDATED}" "${COMPOSE_ENV}" 2> /dev/null; then
			RunAndLog "" "cp:notice" \
				fatal "Failed to copy file." \
				cp -f "${MKTEMP_ENV_UPDATED}" "${COMPOSE_ENV}"
		fi
		RunAndLog "" "rm:notice" \
			warn "Failed to remove temporary {{|File|}}.env{{[-]}} update file." \
			rm -f "${MKTEMP_ENV_UPDATED}"
		run_script 'set_permissions' "${COMPOSE_ENV}"
		#run_script 'unset_needs_env_update' "${COMPOSE_ENV}"
	fi

	# Process all referenced .env.app.appname files. A multi-service app
	# ships more than one such file (the plain one, any real per-service
	# "___service" file, any shared/virtual "-suffix" file) --
	# apptemplate_filelist_into discovers all of them (as "*"-wildcarded
	# patterns), same pattern used by appvars_create (AppVarFileNames ->
	# loop). Falls back to the plain file alone if the template folder has
	# no ".env.app.*" file at all yet.
	if [[ -n ${applist[*]-} ]]; then
		for appname in "${applist[@]-}"; do
			local -a AppFileTemplates
			run_script 'apptemplate_filelist_into' AppFileTemplates "${appname}"
			if [[ -z ${AppFileTemplates[*]-} ]]; then
				AppFileTemplates=(".env.app.*")
			fi
			local FileTemplate
			for FileTemplate in "${AppFileTemplates[@]}"; do
				local QualifiedAppName="${FileTemplate//"*"/"${appname}"}"
				QualifiedAppName="${QualifiedAppName#.env.app.}"
				local APP_ENV_FILE
				run_script 'app_env_file_into' APP_ENV_FILE "${QualifiedAppName}"
				if ! run_script 'needs_env_update' "${APP_ENV_FILE}"; then
					info "File '{{|File|}}${APP_ENV_FILE}{{[-]}}' already updated."
					continue
				fi
				if [[ ! -f ${APP_ENV_FILE} ]]; then
					notice "Creating '{{|File|}}${APP_ENV_FILE}{{[-]}}'."
				else
					notice "Updating '{{|File|}}${APP_ENV_FILE}{{[-]}}'."
				fi
				local APP_DEFAULT_ENV_FILE=""
				if ! run_script 'app_is_user_defined' "${appname}"; then
					run_script 'app_instance_file_into' APP_DEFAULT_ENV_FILE "${appname}" "${FileTemplate}"
				fi
				local -a UPDATED_APP_ENV_LINES=()
				run_script 'env_format_lines_into_array' UPDATED_APP_ENV_LINES "${APP_ENV_FILE}" "${APP_DEFAULT_ENV_FILE}" "${appname}" "${APP_ENV_FILE}"
				local MKTEMP_APP_ENV_UPDATED
				MKTEMP_APP_ENV_UPDATED=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_APP_ENV_UPDATED.XXXXXXXXXX") ||
					fatal \
						"Failed to create temporary update '{{|File|}}.env.app.${QualifiedAppName}{{[-]}}' file." \
						"Failing command: {{|FailingCommand|}}mktemp -t \"${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_APP_ENV_UPDATED.XXXXXXXXXX\"{{[-]}}"
				printf '%s\n' "${UPDATED_APP_ENV_LINES[@]}" > "${MKTEMP_APP_ENV_UPDATED}" ||
					fatal \
						"Failed to write temporary '{{|File|}}.env.app.${QualifiedAppName}{{[-]}}' update file."
				if [[ ! -f ${APP_ENV_FILE} ]] || ! cmp -s "${MKTEMP_APP_ENV_UPDATED}" "${APP_ENV_FILE}" 2> /dev/null; then
					RunAndLog "" "cp:notice" \
						fatal "Failed to copy file." \
						cp -f "${MKTEMP_APP_ENV_UPDATED}" "${APP_ENV_FILE}"
				fi
				RunAndLog "" "rm:notice" \
					warn "Failed to remove temporary '{{|File|}}.env.app.${QualifiedAppName}{{[-]}}' update file." \
					rm -f "${MKTEMP_APP_ENV_UPDATED}"
				run_script 'set_permissions' "${APP_ENV_FILE}"
				#run_script 'unset_needs_env_update' "${APP_ENV_FILE}"
			done
		done
	fi

	#run_script 'env_sanitize'
	run_script 'unset_needs_env_update'
	info "Environment variable files update complete."
}

test_env_update() {
	run_script 'env_update'
}
