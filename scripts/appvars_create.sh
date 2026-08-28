#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create() {
	local -a AppList
	IFS=$' \t\n\r' read -d '' -ra AppList <<< "${*^^}" || true
	for APPNAME in "${AppList[@]}"; do
		local -l appname=${APPNAME}
		local AppName
		run_script 'app_nicename_into' AppName "${APPNAME}"
		if ! run_script 'appname_is_valid' "${appname}"; then
			error "'{{|App|}}${AppName}{{[-]}}' is not a valid application name."
			continue
		fi

		if ! run_script 'needs_appvars_create' "${appname}"; then
			# Variables for app have already been created, nothing to do
			notice "Environment variables already created for '{{|App|}}${AppName}{{[-]}}'"
			continue
		fi

		if run_script 'app_is_builtin' "${AppName}"; then
			local AppDefaultGlobalEnvFile
			run_script 'app_instance_file_into' AppDefaultGlobalEnvFile "${appname}" ".env"

			info "Creating environment variables for '{{|App|}}${AppName}{{[-]}}'."
			if ! run_script 'env_var_exists' "${APPNAME}_ENABLED"; then
				run_script 'env_migrate' "${APPNAME}_ENABLED" "${APPNAME}__ENABLED"
			fi
			if ! run_script 'app_is_added' "${AppName}"; then
				run_script 'enable_app' "${AppName}"
			fi
			run_script 'appvars_migrate' "${AppName}"
			run_script 'env_merge_newonly' "${COMPOSE_ENV}" "${AppDefaultGlobalEnvFile}"

			# A multi-service app ships more than one ".env.app.*" file
			# template (the plain one, any real per-service "___service"
			# file, any shared/virtual "-suffix" file) -- apptemplate_filelist_into
			# discovers all of them (as "*"-wildcarded patterns) so each
			# gets created/merged in turn, same pattern DockSTARTer2 uses
			# (AppVarFileNames -> loop). Falls back to the plain file alone
			# if the template folder has no ".env.app.*" file at all yet.
			local -a AppFileTemplates
			run_script 'apptemplate_filelist_into' AppFileTemplates "${appname}"
			if [[ -z ${AppFileTemplates[*]-} ]]; then
				AppFileTemplates=(".env.app.*")
			fi
			local FileTemplate
			for FileTemplate in "${AppFileTemplates[@]}"; do
				local AppDefaultAppEnvFile AppEnvFile QualifiedAppName
				run_script 'app_instance_file_into' AppDefaultAppEnvFile "${appname}" "${FileTemplate}"
				QualifiedAppName="${FileTemplate//"*"/"${appname}"}"
				QualifiedAppName="${QualifiedAppName#.env.app.}"
				run_script 'app_env_file_into' AppEnvFile "${QualifiedAppName}"
				run_script 'env_merge_newonly' "${AppEnvFile}" "${AppDefaultAppEnvFile}"
			done

			run_script 'appvars_sanitize' "${AppName}"
			info "Environment variables created for '{{|App|}}${AppName}{{[-]}}'."
		else
			warn "Application '{{|App|}}${AppName}{{[-]}}' does not exist."
		fi
		run_script 'unset_needs_appvars_create' "${appname}"
	done
}

test_appvars_create() {
	run_script 'appvars_create' WATCHTOWER
	run_script 'env_update'
	echo "${COMPOSE_ENV}:"
	cat "${COMPOSE_ENV}"
	local EnvFile
	EnvFile="$(run_script 'app_env_file' "watchtower")"
	echo "${EnvFile}:"
	cat "${EnvFile}"
}
