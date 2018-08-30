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
        APPSUPPORTED=false
        if [[ -d ${SCRIPTPATH}/compose/.apps/${FILENAME}/ ]]; then
            if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml ]]; then
                if [[ ${ARCH} == "aarch64" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.arm64.yml ]]; then
                        APPSUPPORTED=true
                    elif [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                        APPSUPPORTED=true
                    fi
                fi
                if [[ ${ARCH} == "armv7l" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                        APPSUPPORTED=true
                    fi
                fi
                if [[ ${ARCH} == "x86_64" ]]; then
                    APPSUPPORTED=true
                fi
            fi
        fi
        if [[ ${APPSUPPORTED} == true ]]; then
            local APPONOFF
            if [[ $(run_script 'env_get' "${APPNAME}_ENABLED") == true ]]; then
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
                "DELUGEVPN")
                    APPLIST+=("DelugeVPN" "Deluge, OpenVPN and Privoxy" "${APPONOFF}")
                    ;;
                "DUCKDNS")
                    APPLIST+=("DuckDNS" "Free service which will point a DNS to an IP of your choice" "${APPONOFF}")
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
                "MYLAR")
                    APPLIST+=("Mylar" "Comic book PVR client" "${APPONOFF}")
                    ;;
                "NETDATA")
                    APPLIST+=("netdata" "Distributed real-time performance and health monitoring" "${APPONOFF}")
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
                "PORTAINERAGENT")
                    APPLIST+=("Portainer Agent" "An agent used to manage all the resources in a Swarm cluster" "${APPONOFF}")
                    ;;
                "RADARR")
                    APPLIST+=("Radarr" "Automatically download movies via Usenet and BitTorrent" "${APPONOFF}")
                    ;;
                "RTORRENTVPN")
                    APPLIST+=("rTorrentVPN" "rTorrent, Flood or ruTorrent WebUI, OpenVPN and Privoxy" "${APPONOFF}")
                    ;;
                "RUTORRENT")
                    APPLIST+=("ruTorrent" "rTorrent client and ruTorrent WebUI" "${APPONOFF}")
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
                "TRANSMISSIONVPN")
                    APPLIST+=("TransmissionVPN" "Transmission, WebUI and OpenVPN" "${APPONOFF}")
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

    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        SELECTEDAPPS=$(whiptail --fb --clear --separate-output --title "Application Selector" --checklist  "Choose which apps you would like to install:" 0 0 0 "${APPLIST[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
        if [[ ${SELECTEDAPPS} == "Cancel" ]]; then
            return 1
        else
            info "Disabling all apps."
            while IFS= read -r line; do
                local APPNAME
                APPNAME=${line/_ENABLED=true/}
                run_script 'env_set' "${APPNAME}_ENABLED" false
            done < <(grep '_ENABLED=true' < "${SCRIPTPATH}/compose/.env")
            info "Enabling selected apps."
            while IFS= read -r line; do
                run_script 'env_set' "$(echo "${line^^}" | tr -d ' ')_ENABLED" true
            done < <(echo "${SELECTEDAPPS}")
        fi
    fi
}
