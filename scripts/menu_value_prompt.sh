#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

menu_value_prompt() {
    local SET_VAR
    SET_VAR=${1:-}

    local CURRENT_VAL
    CURRENT_VAL=$(run_script 'env_get' "${SET_VAR}")

    local DEFAULT_VAL
    DEFAULT_VAL=$(grep "${SET_VAR}" "${SCRIPTPATH}/compose/.env.example" | xargs || true)
    DEFAULT_VAL="${DEFAULT_VAL#*=}"

    local SYSTEM_VAL
    local VALUEDESCRIPTION
    local VALUEOPTIONS
    VALUEOPTIONS=()
    VALUEOPTIONS+=("Keep Current" "${CURRENT_VAL}")

    case "${SET_VAR}" in
        DOCKERCONFDIR)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/.docker/config"
            VALUEOPTIONS+=("Use System" "${SYSTEM_VAL}")
            ;;
        DOCKERSHAREDDIR)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/.docker/shared"
            VALUEOPTIONS+=("Use System" "${SYSTEM_VAL}")
            ;;
        DOWNLOADSDIR)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/Downloads"
            VALUEOPTIONS+=("Use System" "${SYSTEM_VAL}")
            ;;
        MEDIADIR_BOOKS)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/Books"
            VALUEOPTIONS+=("Use System" "${SYSTEM_VAL}")
            ;;
        MEDIADIR_MOVIES)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/Movies"
            VALUEOPTIONS+=("Use System" "${SYSTEM_VAL}")
            ;;
        MEDIADIR_MUSIC)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/Music"
            VALUEOPTIONS+=("Use System" "${SYSTEM_VAL}")
            ;;
        MEDIADIR_TV)
            SYSTEM_VAL="${DETECTED_HOMEDIR}/TV"
            VALUEOPTIONS+=("Use System" "${SYSTEM_VAL}")
            ;;
        PGID)
            SYSTEM_VAL="${DETECTED_PGID}"
            VALUEOPTIONS+=("Use System" "${SYSTEM_VAL}")
            VALUEDESCRIPTION="\\n\\n If this is not the correct user ID please exit and run DockSTARTer as the correct user."
            ;;
        PUID)
            SYSTEM_VAL="${DETECTED_PUID}"
            VALUEOPTIONS+=("Use System" "${SYSTEM_VAL}")
            VALUEDESCRIPTION="\\n\\n If this is not the correct user group please exit and ensure the user running DockSTARTer is assigned the correct group."
            ;;
        TZ)
            SYSTEM_VAL="$(cat /etc/timezone)"
            VALUEOPTIONS+=("Use System" "${SYSTEM_VAL}")
            VALUEDESCRIPTION="\\n\\n If this is not the correct timezone please exit and set your system timezone using sudo dpkg-reconfigure tzdata"
            ;;
        *)
            VALUEOPTIONS+=("Use Default" "${DEFAULT_VAL}")
            ;;
    esac

    VALUEOPTIONS+=("Enter New" "")

    local SELECTEDVALUE
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        SELECTEDVALUE="Keep Current"
    else
        SELECTEDVALUE=$(whiptail --fb --clear --title "Value Prompt" --menu "What would you like set for ${SET_VAR}?${VALUEDESCRIPTION:-}" 0 0 0 "${VALUEOPTIONS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi

    local INPUT
    case "${SELECTEDVALUE}" in
        "Keep Current")
            INPUT=${CURRENT_VAL}
            ;;
        "Use Default")
            INPUT=${DEFAULT_VAL}
            ;;
        "Use System")
            INPUT=${SYSTEM_VAL}
            ;;
        "Enter New")
            INPUT=$(whiptail --fb --clear --title "Enter New" --inputbox "What would you like set for ${SET_VAR}?" 0 0 "${CURRENT_VAL}" 3>&1 1>&2 2>&3 || echo "CancelNewEntry")
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
                if [[ ${INPUT} == "true" ]] || [[ ${INPUT} == "false" ]]; then
                    run_script 'env_set' "${SET_VAR}" "${INPUT}"
                else
                    whiptail --fb --clear --title "Error" --msgbox "${INPUT} is not true or false. Please try setting ${SET_VAR} again." 0 0
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
                    whiptail --fb --clear --title "Error" --msgbox "${INPUT} is not a valid network mode. Please try setting ${SET_VAR} again." 0 0
                    menu_value_prompt "${SET_VAR}"
                fi
                ;;
            *_PORT_*)
                if [[ ${INPUT} =~ ^[0-9]+$ ]] || [[ ${INPUT} -ge 0 ]] || [[ ${INPUT} -le 65535 ]]; then
                    run_script 'env_set' "${SET_VAR}" "${INPUT}"
                else
                    whiptail --fb --clear --title "Error" --msgbox "${INPUT} is not a valid port. Please try setting ${SET_VAR} again." 0 0
                    menu_value_prompt "${SET_VAR}"
                fi
                ;;
            *DIR|*DIR_*)
                if [[ -d ${INPUT} ]]; then
                    run_script 'env_set' "${SET_VAR}" "${INPUT}"
                    local PUID
                    PUID=$(run_script 'env_get' PUID)
                    local PGID
                    PGID=$(run_script 'env_get' PGID)
                    run_script 'set_permissions' "${INPUT}" "${PUID}" "${PGID}"
                else
                    whiptail --fb --clear --title "Error" --msgbox "${INPUT} is not a valid path. Please try setting ${SET_VAR} again." 0 0
                    menu_value_prompt "${SET_VAR}"
                fi
                ;;
            P[GU]ID)
                if [[ ${INPUT} =~ ^[0-9]+$ ]]; then
                    run_script 'env_set' "${SET_VAR}" "${INPUT}"
                else
                    whiptail --fb --clear --title "Error" --msgbox "${INPUT} is not a valid ${SET_VAR}. Please try setting ${SET_VAR} again." 0 0
                    menu_value_prompt "${SET_VAR}"
                fi
                ;;
            *)
                run_script 'env_set' "${SET_VAR}" "${INPUT}"
                ;;
        esac
    fi
}
