#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

integrate_all() {
	# integrate_all
	# Top-level orchestrator for the auto-integration system.
	# Called by the yml_merge hook when GLOBAL_AUTO_INTEGRATE is true,
	# and by the menu's "Run all integrations now" entry.
	#
	# Steps run sequentially; each is best-effort. A failure in one
	# step logs a warning to integration.log and continues.
	#
	# All scripts are idempotent (detect-existing-then-skip / GET-PUT)
	# so concurrent runs from menu + yml_merge are safe by construction.
	{
		printf '\n========================================\n'
		printf '=== integrate_all @ %s ===\n' "$(date -Iseconds)"
		printf '========================================\n'
	} >> "${INTEGRATION_LOG_FILE}" 2>&1 || true

	notice "Starting integration pipeline (logging to ${INTEGRATION_LOG_FILE})."

	local -a steps=(
		"api_key_collect"
		"api_keys_to_env"
		"integrate_npm"
		"integrate_prowlarr"
		"integrate_arr_download_clients"
		"integrate_bazarr"
		"integrate_recyclarr"
		"integrate_grafana_datasources"
		"integrate_homarr"
		"integrate_homepage"
	)

	local step
	for step in "${steps[@]}"; do
		if [[ ! -f ${SCRIPTPATH}/scripts/${step}.sh ]]; then
			notice "Skipping ${step} (script not present)."
			continue
		fi
		notice "==> ${step}"
		run_script "${step}" 2>&1 | tee -a "${INTEGRATION_LOG_FILE}" || \
			warn "${step} reported errors; continuing."
	done

	notice "Integration pipeline complete."
}

test_integrate_all() {
	warn "CI does not test integrate_all (orchestrator)."
}
