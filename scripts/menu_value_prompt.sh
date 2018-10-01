#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

menu_value_prompt() {
    local SET_VAR
    SET_VAR=${1:-}

    local CURRENT_VAL
    CURRENT_VAL=$(run_script 'env_get' "${SET_VAR}")

    local DEFAULT_VAL
    DEFAULT_VAL=$(grep "^${SET_VAR}=" "${SCRIPTPATH}/compose/.env.example" | xargs || true)
    DEFAULT_VAL="${DEFAULT_VAL#*=}"

    local SYSTEM_VAL
    local VALUEDESCRIPTION
    local VALUEOPTIONS
    VALUEOPTIONS=()
    VALUEOPTIONS+=("Keep Current " "${CURRENT_VAL}")

    case "${SET_VAR}" in
        DOCKERCONFDIR)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/.docker/config"
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        DOCKERSHAREDDIR)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/.docker/config/shared"
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        DOWNLOADSDIR)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/Downloads"
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        MEDIADIR_BOOKS)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/Books"
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        MEDIADIR_COMICS)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/Comics"
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        MEDIADIR_MOVIES)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/Movies"
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        MEDIADIR_MUSIC)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/Music"
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        MEDIADIR_TV)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/TV"
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        PGID)
            SYSTEM_VAL="${DETECTED_PGID}"
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        PUID)
            SYSTEM_VAL="${DETECTED_PUID}"
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        TZ)
            SYSTEM_VAL="$(cat /etc/timezone)"
            VALUEOPTIONS+=("Use System " "${SYSTEM_VAL}")
            ;;
        *)
            VALUEOPTIONS+=("Use Default " "${DEFAULT_VAL}")
            ;;
    esac

    VALUEOPTIONS+=("Enter New " "")

    case "${SET_VAR}" in
        *_ENABLED)
            VALUEDESCRIPTION="\\n\\n Must be true or false."
            ;;
        *_NETWORK_MODE)
            VALUEDESCRIPTION="\\n\\n Network Mode is usually left blank but can also be bridge, host, none, service: <APPNAME>, or container: <APPNAME>."
            ;;
        *_PORT_*)
            VALUEDESCRIPTION="\\n\\n Must be an unused port between 0 and 65535."
            ;;
        *DIR|*DIR_*)
            VALUEDESCRIPTION="\\n\\n If the directory selected does not exist we will attempt to create it."
            ;;
        LAN_NETWORK)
            VALUEDESCRIPTION="\\n\\n This is used to define your home LAN network, do NOT confuse this with the IP address of your router or your server, the value for this key defines your network NOT a single host. Please Google CIDR Notation to learn more."
            ;;
        PGID)
            VALUEDESCRIPTION="\\n\\n This should be your user group ID. If you are unsure, select Use System."
            ;;
        PUID)
            VALUEDESCRIPTION="\\n\\n This should be your user account ID. If you are unsure, select Use System."
            ;;
        TZ)
            VALUEDESCRIPTION="\\n\\n If this is not the correct timezone please exit and set your system timezone."
            ;;
        VPN_ENABLE)
            VALUEDESCRIPTION="\\n\\n Must be yes or no."
            ;;
        VPN_OPTIONS)
            VALUEDESCRIPTION="\\n\\n Additional openvpn cli options."
            ;;
        VPN_PROV)
            VALUEDESCRIPTION="\\n\\n VPN Provider, usually pia, airvpn or custom."
            ;;
        *)
            VALUEDESCRIPTION=""
            ;;
    esac

    local SELECTEDVALUE
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        SELECTEDVALUE="Keep Current "
    else
        SELECTEDVALUE=$(whiptail --fb --clear --title "DockSTARTer" --menu "What would you like set for ${SET_VAR}?${VALUEDESCRIPTION:-}" 0 0 0 "${VALUEOPTIONS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi

    local INPUT
    case "${SELECTEDVALUE}" in
        "Keep Current ")
            INPUT=${CURRENT_VAL}
            ;;
        "Use Default ")
            INPUT=${DEFAULT_VAL}
            ;;
        "Use System ")
            INPUT=${SYSTEM_VAL}
            ;;
        "Enter New ")
            INPUT=$(whiptail --fb --clear --title "DockSTARTer" --inputbox "What would you like set for ${SET_VAR}?" 0 0 "${CURRENT_VAL}" 3>&1 1>&2 2>&3 || echo "CancelNewEntry")
            ;;
        "Cancel")
            warning "Selection of ${SET_VAR} was canceled."
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
                if [[ -z ${INPUT} ]] || \
                    [[ ${INPUT} == "bridge" ]] || \
                    [[ ${INPUT} == "host" ]] || \
                    [[ ${INPUT} == "none" ]] || \
                    [[ ${INPUT} == "service:"* ]] || \
                    [[ ${INPUT} == "container:"* ]]; then
                    run_script 'env_set' "${SET_VAR}" "${INPUT}"
                else
                    whiptail --fb --clear --title "DockSTARTer" --msgbox "${INPUT} is not a valid network mode. Please try setting ${SET_VAR} again." 0 0
                    menu_value_prompt "${SET_VAR}"
                fi
                ;;
            *_PORT_*)
                if [[ ${INPUT} =~ ^[0-9]+$ ]] || [[ ${INPUT} -ge 0 ]] || [[ ${INPUT} -le 65535 ]]; then
                    run_script 'env_set' "${SET_VAR}" "${INPUT}"
                else
                    whiptail --fb --clear --title "DockSTARTer" --msgbox "${INPUT} is not a valid port. Please try setting ${SET_VAR} again." 0 0
                    menu_value_prompt "${SET_VAR}"
                fi
                ;;
            *DIR|*DIR_*)
                local PUID
                PUID=$(run_script 'env_get' PUID)
                local PGID
                PGID=$(run_script 'env_get' PGID)
                if [[ ${INPUT} == "/" ]]; then
                    whiptail --fb --clear --title "DockSTARTer" --msgbox "Cannot use / for ${SET_VAR}. Please select another folder." 0 0
                    menu_value_prompt "${SET_VAR}"
                elif [[ ${INPUT} == "~*" ]]; then
                    local CORRECTED_DIR
                    CORRECTED_DIR="${DETECTED_HOMEDIR}${INPUT/*~/}"
                    local ANSWER
                    set +e
                    ANSWER=$(whiptail --fb --clear --title "DockSTARTer" --yesno "Cannot use the ~ shortcut in ${SET_VAR}. Would you like to use ${CORRECTED_DIR} instead?." 0 0 3>&1 1>&2 2>&3; echo $?)
                    set -e
                    if [[ ${ANSWER} == 0 ]]; then
                        run_script 'env_set' "${SET_VAR}" "${CORRECTED_DIR}"
                        whiptail --fb --clear --title "DockSTARTer" --msgbox "Returning to the previous menu to confirm selection." 0 0
                    else
                        whiptail --fb --clear --title "DockSTARTer" --msgbox "Cannot use the ~ shortcut in ${SET_VAR}. Please select another folder." 0 0
                    fi
                    menu_value_prompt "${SET_VAR}"
                elif [[ -d ${INPUT} ]]; then
                    run_script 'env_set' "${SET_VAR}" "${INPUT}"
                    local ANSWER
                    set +e
                    ANSWER=$(whiptail --fb --clear --title "DockSTARTer" --yesno "Would you like to set permissions on ${INPUT} ?" 0 0 3>&1 1>&2 2>&3; echo $?)
                    set -e
                    if [[ ${ANSWER} == 0 ]]; then
                        run_script 'set_permissions' "${INPUT}" "${PUID}" "${PGID}"
                    fi
                else
                    local ANSWER
                    set +e
                    ANSWER=$(whiptail --fb --clear --title "DockSTARTer" --yesno "${INPUT} is not a valid path. Would you like to attempt to create it?" 0 0 3>&1 1>&2 2>&3; echo $?)
                    set -e
                    if [[ ${ANSWER} == 0 ]]; then
                        mkdir -p "${INPUT}" || fatal "${INPUT} folder could not be created."
                        run_script 'set_permissions' "${INPUT}" "${PUID}" "${PGID}"
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
                    local ANSWER
                    set +e
                    ANSWER=$(whiptail --fb --clear --title "DockSTARTer" --yesno "Running as root is not recommended. Would you like to select a different ID?" 0 0 3>&1 1>&2 2>&3; echo $?)
                    set -e
                    if [[ ${ANSWER} == 0 ]]; then
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
