#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_integrations() {
	local Title="Integrations"

	local Opt_ToggleAuto="Toggle GLOBAL_AUTO_INTEGRATE"
	local Opt_SetDomain="Set GLOBAL_DOMAIN"
	local Opt_SetCertEmail="Set GLOBAL_CERT_EMAIL"
	local Opt_CollectKeys="Collect API keys now"
	local Opt_ViewKeys="View collected keys (redacted)"
	local Opt_RevealKeys="Reveal keys (10 s)"
	local Opt_ViewLog="View integration log"
	local Opt_RunAll="Run all integrations now"

	local LastChoice=""
	while true; do
		local AutoIntegrate="" Domain="" CertEmail=""
		run_script 'env_get_into' AutoIntegrate "GLOBAL_AUTO_INTEGRATE" 2> /dev/null || true
		run_script 'env_get_into' Domain "GLOBAL_DOMAIN" 2> /dev/null || true
		run_script 'env_get_into' CertEmail "GLOBAL_CERT_EMAIL" 2> /dev/null || true

		local -a Opts=(
			"${Opt_ToggleAuto}" "{{|ListDefault|}}Currently: ${AutoIntegrate:-false}"
			"${Opt_SetDomain}" "{{|ListDefault|}}Currently: ${Domain:-<unset>}"
			"${Opt_SetCertEmail}" "{{|ListDefault|}}Currently: ${CertEmail:-<unset>}"
			"${Opt_CollectKeys}" "{{|ListDefault|}}Scrape API keys from each enabled app's config file"
			"${Opt_ViewKeys}" "{{|ListDefault|}}Display collected keys (redacted, last 4 chars visible)"
			"${Opt_RevealKeys}" "{{|ListDefault|}}Briefly display full collected keys for 10 seconds"
			"${Opt_ViewLog}" "{{|ListDefault|}}Tail the dedicated integration log file"
			"${Opt_RunAll}" "{{|ListDefault|}}Run the full integration pipeline now (Phase 4+)"
		)

		local -a ChoiceDialog=(
			"${Title}"
			"Configure and run app-to-app integrations"
			--ok-label:Select
			--extra-label:Back
			--cancel-label:Exit
			--default-item:"${LastChoice}"
			"${Opts[@]}"
		)
		local Choice
		local -i ButtonPressed=0
		Choice=$(dialog_menu "${ChoiceDialog[@]}") || ButtonPressed=$?
		LastChoice=${Choice}

		case ${DIALOG_BUTTONS[ButtonPressed]-} in
			OK)
				case "${Choice}" in
					"${Opt_ToggleAuto}")
						_menu_integrations_toggle "GLOBAL_AUTO_INTEGRATE" "${AutoIntegrate}"
						;;
					"${Opt_SetDomain}")
						_menu_integrations_input "GLOBAL_DOMAIN" "${Domain}" \
							"Enter the base domain (e.g. home.example.com). Each enabled app will be reachable at <appname>.<this-domain> through NPM."
						;;
					"${Opt_SetCertEmail}")
						_menu_integrations_input "GLOBAL_CERT_EMAIL" "${CertEmail}" \
							"Enter the email used for Let's Encrypt registration AND the NPM admin user during bootstrap."
						;;
					"${Opt_CollectKeys}")
						run_script_dialog "{{|TitleSuccess|}}Integrations" "Collecting API keys" "" \
							'api_key_collect' || true
						;;
					"${Opt_ViewKeys}")
						_menu_integrations_view_keys "redacted"
						;;
					"${Opt_RevealKeys}")
						_menu_integrations_view_keys "reveal"
						;;
					"${Opt_ViewLog}")
						_menu_integrations_view_log
						;;
					"${Opt_RunAll}")
						if [[ -f ${SCRIPTPATH}/scripts/integrate_all.sh ]]; then
							run_script_dialog "{{|TitleSuccess|}}Integrations" "Running all integrations" "" \
								'integrate_all' || true
						else
							notice "integrate_all is not available yet (Phase 4 has not been installed)."
						fi
						;;
				esac
				;;
			EXTRA | ESC)
				return
				;;
			CANCEL)
				run_script 'menu_exit'
				;;
			*)
				invalid_dialog_button ${ButtonPressed}
				;;
		esac
	done
}

_menu_integrations_toggle() {
	local var=${1-}
	local current=${2-}
	local next="true"
	if is_true "${current}"; then
		next="false"
	fi
	run_script 'env_set' "${var}" "${next}"
}

_menu_integrations_input() {
	local var=${1-}
	local current=${2-}
	local prompt=${3-}
	local NewValue
	NewValue=$(dialog_inputbox "${var}" "${prompt}" "${current}") || return 0
	run_script 'env_set' "${var}" "${NewValue}"
}

_menu_integrations_view_keys() {
	local mode=${1:-redacted}
	if [[ ! -f ${API_KEYS_TOML_FILE} ]]; then
		dialog_msgbox "Integrations" "No keys collected yet. Use 'Collect API keys now' first."
		return
	fi

	local TempView
	TempView=$(mktemp -t "${APPLICATION_NAME}.view_keys.XXXXXXXXXX")
	if [[ ${mode} == "redacted" ]]; then
		sed -E 's/(=[[:space:]]*["'\''])([^"'\'']*)(["'\''])/\1********\3/' \
			"${API_KEYS_TOML_FILE}" > "${TempView}"
	else
		cp "${API_KEYS_TOML_FILE}" "${TempView}"
	fi

	_menu_integrations_show_file "Collected API keys (${mode})" "${TempView}" "${mode}"
	rm -f "${TempView}"
}

_menu_integrations_view_log() {
	if [[ ! -f ${INTEGRATION_LOG_FILE} ]]; then
		dialog_msgbox "Integrations" "Integration log is empty (no runs yet)."
		return
	fi
	_menu_integrations_show_file "Integration log" "${INTEGRATION_LOG_FILE}" "log"
}

_menu_integrations_show_file() {
	local title=${1-}
	local file=${2-}
	local mode=${3-}
	local -i timeout=0
	if [[ ${mode} == "reveal" ]]; then
		timeout=10
	fi
	set_screen_size
	local -i WindowHeight=$((LINES - D["WindowRowsAdjust"]))
	local -i WindowWidth=$((COLUMNS - D["WindowColsAdjust"]))
	if [[ ${timeout} -gt 0 ]]; then
		_dialog_ --title "{{|Title|}}${title}" \
			--timeout "${timeout}" \
			--textbox "${file}" "${WindowHeight}" "${WindowWidth}" || true
	else
		_dialog_ --title "{{|Title|}}${title}" \
			--textbox "${file}" "${WindowHeight}" "${WindowWidth}" || true
	fi
	echo -n "${S["BS"]}" >&2
}

test_menu_integrations() {
	warn "CI does not test menu_integrations (interactive)."
}
