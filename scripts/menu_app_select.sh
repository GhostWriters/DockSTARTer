#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

menu_app_select() {
    local APPLIST
    APPLIST=()

    while IFS= read -r line; do
        local APPNAME
        APPNAME=${line/_ENABLED=*/}
        local FILENAME
        FILENAME=${APPNAME,,}
        local APPSUPPORTED
        APPSUPPORTED="false"
        if [[ -d ${SCRIPTPATH}/compose/.apps/${FILENAME}/ ]]; then
            if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml ]]; then
                if [[ ${ARCH} == "arm64" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.arm64.yml ]]; then
                        APPSUPPORTED="true"
                    elif [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                        APPSUPPORTED="true"
                    fi
                fi
                if [[ ${ARCH} == "armhf" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                        APPSUPPORTED="true"
                    fi
                fi
                if [[ ${ARCH} == "amd64" ]]; then
                    APPSUPPORTED="true"
                fi
            fi
        fi
        if [[ ${APPSUPPORTED} == "true" ]]; then
            local APPONOFF
            if [[ $(run_script 'env_get' "${APPNAME}_ENABLED") == "true" ]]; then
                APPONOFF="on"
            else
                APPONOFF="off"
            fi
            case "${APPNAME}" in
                "BAZARR")
                    APPLIST+=("Bazarr" "Companion to Sonarr to manage and download subtitles" "${APPONOFF}")
                    ;;
                "COUCHPOTATO")
                    APPLIST+=("Couchpotato" "Movies PVR Client" "${APPONOFF}")
                    ;;
                "DELUGE")
                    APPLIST+=("Deluge" "Lightweight, Full-featured BitTorrent client" "${APPONOFF}")
                    ;;
                "DUCKDNS")
                    APPLIST+=("DuckDNS" "free service which will point a DNS to an IP of your choice" "${APPONOFF}")
                    ;;
                "DUPLICATI")
                    APPLIST+=("Duplicati" "Backup software to store backups online with strong encryption" "${APPONOFF}")
                    ;;
                "EMBY")
                    APPLIST+=("Emby" "Organize, play, and stream audio and video" "${APPONOFF}")
                    ;;
                "HEADPHONES")
                    APPLIST+=("Headphones" "Music PVR Client" "${APPONOFF}")
                    ;;
                "HOMEASSISTANT")
                    APPLIST+=("Home Assistant" "Track and control all devices at home and automate control" "${APPONOFF}")
                    ;;
                "HYDRA2")
                    APPLIST+=("Hydra2" "Meta search for NZB indexers" "${APPONOFF}")
                    ;;
                "JACKETT")
                    APPLIST+=("Jackett" "API Support for your favorite private trackers" "${APPONOFF}")
                    ;;
                "LAZYLIBRARIAN")
                    APPLIST+=("Lazylibrarian" "Book PVR Client" "${APPONOFF}")
                    ;;
                "LETSENCRYPT")
                    APPLIST+=("Letsencrypt" "Certificate authority that provides free X.509 certificates" "${APPONOFF}")
                    ;;
                "LIDARR")
                    APPLIST+=("Lidarr" "Music download manager for Usenet and BitTorrent users" "${APPONOFF}")
                    ;;
                "LOGARR")
                    APPLIST+=("Logarr" "Self-hosted, single-page, log consolidation tool" "${APPONOFF}")
                    ;;
                "MEDUSA")
                    APPLIST+=("Medusa" "Automatic Video Library Manager for TV Shows" "${APPONOFF}")
                    ;;
                "MONITORR")
                    APPLIST+=("Monitorr" "Webfront to live display the status of any webapp or service" "${APPONOFF}")
                    ;;
                "MUXIMUX")
                    APPLIST+=("Muximux" "A lightweight way to manage your HTPC" "${APPONOFF}")
                    ;;
                "NZBGET")
                    APPLIST+=("NZBGet" "NZB Newsgrabber / Downloader" "${APPONOFF}")
                    ;;
                "OMBI")
                    APPLIST+=("Ombi" "Allow your users to Request Movies, TV Shows and Albums" "${APPONOFF}")
                    ;;
                "ORGANIZR")
                    APPLIST+=("Organizr" "HTPC/Homelab Services Organizer" "${APPONOFF}")
                    ;;
                "PLEX")
                    APPLIST+=("Plex" "Organizes all of your video, music and photo collections" "${APPONOFF}")
                    ;;
                "PLEXREQUESTS")
                    APPLIST+=("Plex Requests" "Automated way for users to request new content for Plex" "${APPONOFF}")
                    ;;
                "PORTAINER")
                    APPLIST+=("Portainer" "Simple management UI for Docker" "${APPONOFF}")
                    ;;
                "RADARR")
                    APPLIST+=("Radarr" "Automatically download movies via Usenet and BitTorrent" "${APPONOFF}")
                    ;;
                "RUTORRENT")
                    APPLIST+=("ruTorrent" "Web front-end for rTorrent" "${APPONOFF}")
                    ;;
                "SABNZBD")
                    APPLIST+=("SABnzbd" "NZB Newsgrabber / Downloader" "${APPONOFF}")
                    ;;
                "SICKRAGE")
                    APPLIST+=("Sickrage" "Automatic Video Library Manager for TV Shows" "${APPONOFF}")
                    ;;
                "SONARR")
                    APPLIST+=("Sonarr" "Smart TV show PVR via Usenet and BitTorrent" "${APPONOFF}")
                    ;;
                "SYNCTHING")
                    APPLIST+=("Syncthing" "Open-source peer-to-peer file synchronization" "${APPONOFF}")
                    ;;
                "TAUTULLI")
                    APPLIST+=("Tautulli" "Monitoring and tracking tool for Plex Media Server" "${APPONOFF}")
                    ;;
                "TRANSMISSION")
                    APPLIST+=("Transmission" "Fast, easy, and free BitTorrent client" "${APPONOFF}")
                    ;;
                "UNIFI")
                    APPLIST+=("Unifi" "Controller software for wireless networks" "${APPONOFF}")
                    ;;
                "WATCHER")
                    APPLIST+=("Watcher" "Automated movie NZB & Torrent searcher and snatcher" "${APPONOFF}")
                    ;;
                "WATCHTOWER")
                    APPLIST+=("Watchtower" "Automatically update running Docker containers" "${APPONOFF}")
                    ;;
                *)
                    warning "WARNING ${APPNAME} APP DESCRIPTION NOT FOUND"
                    APPLIST+=("${APPNAME}" "Description not found" "${APPONOFF}")
                    ;;
            esac
        fi
    done < <(grep '_ENABLED=' < "${SCRIPTPATH}/compose/.env")

    # Might need to be adjusted if more applications are added
    local LINES
    LINES=$(stty size | cut '-d ' -f1)
    LINES=$((LINES<27?LINES:27))

    local COLUMNS
    COLUMNS=$(stty size | cut '-d ' -f2)
    COLUMNS=$((COLUMNS<92?COLUMNS:92))

    local NETLINES
    NETLINES=$((LINES-10))

    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        SELECTEDAPPS=$(whiptail --fb --title "Application Selector" --checklist --separate-output "Choose which apps you would like to install:" ${LINES} ${COLUMNS} ${NETLINES} "${APPLIST[@]}" 3>&1 1>&2 2>&3)
        reset || true
        while IFS= read -r line; do
            run_script 'env_set' "$(echo "${line^^}" | tr -d ' ')_ENABLED" 'true'
        done < <(echo "${SELECTEDAPPS}")
    fi
}
