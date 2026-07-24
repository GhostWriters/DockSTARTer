#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_options_package_manager() {
	if [[ ${CI-} == true ]]; then
		return
	fi

	local Title="Choose Package Manager"

	local PM_AutoDetect_Tag="<Autodetect>"
	local PM_Autodetect_Item="Automatically detect the package manager to use"

	run_script 'config_package_manager' &> /dev/null

	local CurrentPackageManager
	run_script 'config_get_into' CurrentPackageManager pm.package_manager || true

	local -a PackageManagerList
	run_script 'package_manager_list_into_array' PackageManagerList

	local LastChoice="${PM_AutoDetect_Tag}"

	local -a PM_Tag
	local -A PM_PackageManager PM_Item
	PM_Tag=("${PM_AutoDetect_Tag}")
	PM_PackageManager["${PM_AutoDetect_Tag}"]=''

	PM_Item["${PM_AutoDetect_Tag}"]="${PM_Autodetect_Item}"
	for PackageManager in "${PackageManagerList[@]}"; do
		local Tag
		run_script 'package_manager_nicename_into' Tag "${PackageManager}"
		PM_Tag+=("${Tag}")
		PM_PackageManager["${Tag}"]="${PackageManager}"
		local desc
		run_script 'package_manager_description_into' desc "${PackageManager}"
		PM_Item["${Tag}"]="${desc}"
		if [[ ${PackageManager} == "${CurrentPackageManager}" ]]; then
			LastChoice="${Tag}"
		fi
	done

	while true; do
		local -a Opts=()
		for Tag in "${PM_Tag[@]-}"; do
			local ItemColor="{{|ListAppUserDefined|}}"
			if [[ ${Tag} == "${PM_AutoDetect_Tag}" ]] || run_script 'package_manager_exists' "${PM_PackageManager["${Tag}"]}"; then
				ItemColor="{{|ListApp|}}"
			fi
			if [[ ${PM_PackageManager["${Tag}"]} == "${CurrentPackageManager}" ]]; then
				Opts+=("${Tag}" "${ItemColor}${PM_Item["${Tag}"]}" ON "")
			else
				Opts+=("${Tag}" "${ItemColor}${PM_Item["${Tag}"]}" OFF "")
			fi
		done
		local -a ChoiceDialog=(
			"${Title}"
			"Select the package manager to use. Detected package managers are highlighted."
			--item-help
			--ok-label:Select
			--cancel-label:Back
			--exit-button
			--default-item:"${LastChoice}"
			"${Opts[@]}"
		)
		local Choice
		local -i DialogButtonPressed=0
		tui_radiolist_into Choice "${ChoiceDialog[@]}" || DialogButtonPressed=$?
		LastChoice=${Choice}
		case ${DIALOG_BUTTONS[DialogButtonPressed]-} in
			OK)
				if [[ ${PM_PackageManager["${Choice}"]} != "${CurrentPackageManager}" ]]; then
					CurrentPackageManager=${PM_PackageManager["${Choice}"]}
					run_script 'config_package_manager' "${CurrentPackageManager}" &> /dev/null
				fi
				;;
			CANCEL | ESC)
				return
				;;
			EXIT)
				run_script 'menu_exit' || true
				;;
			*)
				invalid_tui_button ${DialogButtonPressed}
				;;
		esac
	done
}

test_menu_options_package_manager() {
	warn "CI does not test menu_options_package_manager."
}
