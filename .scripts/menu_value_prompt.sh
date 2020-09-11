#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_value_prompt() {
    local SET_VAR=${1:-}

    local CURRENT_VAL
    CURRENT_VAL=$(run_script 'env_get' "${SET_VAR}")

    local APPNAME=${SET_VAR%%_*}
    local FILENAME=${APPNAME,,}
    local VAR_LABEL=${SET_VAR,,}

    local DEFAULT_VAL
    if grep -q -Po "^${SET_VAR}=\K.*" "${SCRIPTPATH}/compose/.env.example"; then
        DEFAULT_VAL=$(grep --color=never -Po "^${SET_VAR}=\K.*" "${SCRIPTPATH}/compose/.env.example" || true)
    else
        DEFAULT_VAL=$(run_script 'yml_get' "${APPNAME}" "services.${FILENAME}.labels[com.dockstarter.appvars.${VAR_LABEL}]" || true)
    fi

    local HOME_VAL
    local SYSTEM_VAL
    local VALUEDESCRIPTION
    local VALUEOPTIONS=()
    VALUEOPTIONS+=("Keep Current " "${CURRENT_VAL}")

    case "${SET_VAR}" in
        DOCKERCONFDIR)
            HOME_VAL="${DETECTED_HOMEDIR}/.config/appdata"
            VALUEOPTIONS+=("Use Home " "${HOME_VAL}")
            ;;
        DOCKERGID)
            SYSTEM_VAL=$(cut -d: -f3 < <(getent group docker))
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        DOCKERHOSTNAME)
            SYSTEM_VAL=${HOSTNAME}
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        DOCKERSTORAGEDIR)
            HOME_VAL="${DETECTED_HOMEDIR}/storage"
            VALUEOPTIONS+=("Use Home " "${HOME_VAL}")
            ;;
        LAN_NETWORK)
            SYSTEM_VAL=$(run_script 'detect_lan_network')
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        PGID)
            SYSTEM_VAL=${DETECTED_PGID}
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        PUID)
            SYSTEM_VAL=${DETECTED_PUID}
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        TZ)
            SYSTEM_VAL=$(cat /etc/timezone)
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        *)
            VALUEOPTIONS+=("Use Default " "${DEFAULT_VAL}")
            ;;
    esac

    VALUEOPTIONS+=("Enter New " "")

    case "${SET_VAR}" in
        *_ENABLED)
            VALUEDESCRIPTION='\n\n Must be true or false.'
            ;;
        *_NETWORK_MODE)
            VALUEDESCRIPTION='\n\n Network Mode is usually left blank but can also be bridge, host, none, service: <APPNAME>, or container: <APPNAME>.'
            ;;
        *_PORT_*)
            VALUEDESCRIPTION='\n\n Must be an unused port between 0 and 65535.'
            ;;
        *DIR | *DIR_*)
            VALUEDESCRIPTION='\n\n If the directory selected does not exist we will attempt to create it.'
            ;;
        LAN_NETWORK)
            VALUEDESCRIPTION='\n\n This is used to define your home LAN network, do NOT confuse this with the IP address of your router or your server, the value for this key defines your network NOT a single host. Please Google CIDR Notation to learn more.'
            ;;
        PGID)
            VALUEDESCRIPTION='\n\n This should be your user group ID. If you are unsure, select Use System.'
            ;;
        PUID)
            VALUEDESCRIPTION='\n\n This should be your user account ID. If you are unsure, select Use System.'
            ;;
        TZ)
            VALUEDESCRIPTION='\n\n If this is not the correct timezone please exit and set your system timezone.'
            ;;
        VPN_ENABLE)
            VALUEDESCRIPTION='\n\n Must be yes or no.'
            ;;
        VPN_OPTIONS)
            VALUEDESCRIPTION='\n\n Additional openvpn cli options.'
            ;;
        VPN_PROV)
            VALUEDESCRIPTION='\n\n VPN Provider, usually pia, airvpn or custom.'
            ;;
        *)
            VALUEDESCRIPTION=""
            ;;
    esac

    if [[ -n ${SYSTEM_VAL:-} ]]; then
        VALUEDESCRIPTION="\n\n System detected values are recommended.${VALUEDESCRIPTION}"
    fi

    local SELECTEDVALUE
    if [[ ${CI:-} == true ]]; then
        SELECTEDVALUE="Keep Current "
    else
        SELECTEDVALUE=$(whiptail --fb --clear --title "DockSTARTer" --menu "What would you like set for ${SET_VAR}?${VALUEDESCRIPTION}" 0 0 0 "${VALUEOPTIONS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi

    local INPUT
    case "${SELECTEDVALUE}" in
        "Keep Current ")
            INPUT=${CURRENT_VAL}
            ;;
        "Use Home ")
            INPUT=${HOME_VAL}
            ;;
        "Use Default ")
            INPUT=${DEFAULT_VAL}
            ;;
        "Use System ")
            INPUT=${SYSTEM_VAL}
            ;;
        "Enter New ")
            INPUT=$(whiptail --fb --clear --title "DockSTARTer" --inputbox "What would you like set for ${SET_VAR}?${VALUEDESCRIPTION}" 0 0 "${CURRENT_VAL}" 3>&1 1>&2 2>&3 || echo "CancelNewEntry")
            ;;
        "Cancel")
            warn "Selection of ${SET_VAR} was canceled."
            return 1
            ;;
        *)
            fatal "Invalid Option."
            ;;
    esac

    if [[ ${INPUT} == "CancelNewEntry" ]]; then
        menu_value_prompt "${SET_VAR}"
    else
        case "${SET_VAR}" in
            *_ENABLED)
                if [[ ${INPUT} == true ]] || [[ ${INPUT} == false ]]; then
                    run_script 'env_set' "${SET_VAR}" "${INPUT}"
                else
                    whiptail --fb --clear --title "DockSTARTer" --msgbox "${INPUT} is not true or false. Please try setting ${SET_VAR} again." 0 0
                    menu_value_prompt "${SET_VAR}"
                fi
                ;;
            *_NETWORK_MODE)
                case "${INPUT}" in
                    "" | "bridge" | "host" | "none" | "service:"* | "container:"*)
                        run_script 'env_set' "${SET_VAR}" "${INPUT}"
                        ;;
                    *)
                        whiptail --fb --clear --title "DockSTARTer" --msgbox "${INPUT} is not a valid network mode. Please try setting ${SET_VAR} again." 0 0
                        menu_value_prompt "${SET_VAR}"
                        ;;
                esac
                ;;
            *_PORT_*)
                if [[ ${INPUT} =~ ^[0-9]+$ ]] || [[ ${INPUT} -ge 0 ]] || [[ ${INPUT} -le 65535 ]]; then
                    run_script 'env_set' "${SET_VAR}" "${INPUT}"
                else
                    whiptail --fb --clear --title "DockSTARTer" --msgbox "${INPUT} is not a valid port. Please try setting ${SET_VAR} again." 0 0
                    menu_value_prompt "${SET_VAR}"
                fi
                ;;
            *DIR | *DIR_*)
                if [[ ${INPUT} == "/" ]]; then
                    whiptail --fb --clear --title "DockSTARTer" --msgbox "Cannot use / for ${SET_VAR}. Please select another folder." 0 0
                    menu_value_prompt "${SET_VAR}"
                elif [[ ${INPUT} == ~* ]]; then
                    local CORRECTED_DIR="${DETECTED_HOMEDIR}${INPUT#*~}"
                    if run_script 'question_prompt' "${PROMPT:-}" Y "Cannot use the ~ shortcut in ${SET_VAR}. Would you like to use ${CORRECTED_DIR} instead?"; then
                        run_script 'env_set' "${SET_VAR}" "${CORRECTED_DIR}"
                        whiptail --fb --clear --title "DockSTARTer" --msgbox "Returning to the previous menu to confirm selection." 0 0
                    else
                        whiptail --fb --clear --title "DockSTARTer" --msgbox "Cannot use the ~ shortcut in ${SET_VAR}. Please select another folder." 0 0
                    fi
                    menu_value_prompt "${SET_VAR}"
                elif [[ -d ${INPUT} ]]; then
                    run_script 'env_set' "${SET_VAR}" "${INPUT}"
                    if run_script 'question_prompt' "${PROMPT:-}" Y "Would you like to set permissions on ${INPUT} ?"; then
                        run_script 'set_permissions' "${INPUT}"
                    fi
                else
                    if run_script 'question_prompt' "${PROMPT:-}" Y "${INPUT} is not a valid path. Would you like to attempt to create it?"; then
                        mkdir -p "${INPUT}" || fatal "${INPUT} folder could not be created."
                        run_script 'set_permissions' "${INPUT}"
                        run_script 'env_set' "${SET_VAR}" "${INPUT}"
                        whiptail --fb --clear --title "DockSTARTer" --msgbox "${INPUT} folder was created successfully." 0 0
                    else
                        whiptail --fb --clear --title "DockSTARTer" --msgbox "${INPUT} is not a valid path. Please try setting ${SET_VAR} again." 0 0
                        menu_value_prompt "${SET_VAR}"
                    fi
                fi
                ;;
            P[GU]ID)
                if [[ ${INPUT} == "0" ]]; then
                    if run_script 'question_prompt' "${PROMPT:-}" Y "Running as root is not recommended. Would you like to select a different ID?"; then
                        menu_value_prompt "${SET_VAR}"
                    else
                        run_script 'env_set' "${SET_VAR}" "${INPUT}"
                    fi
                elif [[ ${INPUT} =~ ^[0-9]+$ ]]; then
                    run_script 'env_set' "${SET_VAR}" "${INPUT}"
                else
                    whiptail --fb --clear --title "DockSTARTer" --msgbox "${INPUT} is not a valid ${SET_VAR}. Please try setting ${SET_VAR} again." 0 0
                    menu_value_prompt "${SET_VAR}"
                fi
                ;;
            *)
                run_script 'env_set' "${SET_VAR}" "${INPUT}"
                ;;
        esac
    fi
}

test_menu_value_prompt() {
    # run_script 'menu_value_prompt'
    warn "CI does not test menu_value_prompt."
}
