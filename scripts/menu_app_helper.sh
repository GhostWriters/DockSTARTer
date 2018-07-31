#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

menu_app_helper() {
    GetMenuItem() {
        local APPNAME
        APPNAME="${1}"
        local APPENABLED
        APPENABLED=$(run_script 'env_get' "${APPNAME}_ENABLED")
        local APPONOFF
        if [[ ${APPENABLED} == "true" ]]; then
            APPONOFF="on"
        else
            APPONOFF="off"
        fi
        case "${APPNAME}" in
            "BAZARR")
                SupportedAppDescr+=("Bazarr" "Companion to Sonarr to manage and download subtitles" "${APPONOFF}")
                ;;
            "COUCHPOTATO")
                SupportedAppDescr+=("Couchpotato" "Movies PVR Client" "${APPONOFF}")
                ;;
            "DELUGE")
                SupportedAppDescr+=("Deluge" "Lightweight, Full-featured BitTorrent client" "${APPONOFF}")
                ;;
            "DUCKDNS")
                SupportedAppDescr+=("DuckDNS" "free service which will point a DNS to an IP of your choice" "${APPONOFF}")
                ;;
            "DUPLICATI")
                SupportedAppDescr+=("Duplicati" "Backup software to store backups online with strong encryption" "${APPONOFF}")
                ;;
            "EMBY")
                SupportedAppDescr+=("Emby" "Organize, play, and stream audio and video" "${APPONOFF}")
                ;;
            "HEADPHONES")
                SupportedAppDescr+=("Headphones" "Music PVR Client" "${APPONOFF}")
                ;;
            "HOMEASSISTANT")
                SupportedAppDescr+=("Home Assistant" "Track and control all devices at home and automate control" "${APPONOFF}")
                ;;
            "HYDRA2")
                SupportedAppDescr+=("Hydra2" "Meta search for NZB indexers" "${APPONOFF}")
                ;;
            "JACKETT")
                SupportedAppDescr+=("Jackett" "API Support for your favorite private trackers" "${APPONOFF}")
                ;;
            "LAZYLIBRARIAN")
                SupportedAppDescr+=("Lazylibrarian" "Book PVR Client" "${APPONOFF}")
                ;;
            "LETSENCRYPT")
                SupportedAppDescr+=("Letsencrypt" "Certificate authority that provides free X.509 certificates" "${APPONOFF}")
                ;;
            "LIDARR")
                SupportedAppDescr+=("Lidarr" "Music download manager for Usenet and BitTorrent users" "${APPONOFF}")
                ;;
            "LOGARR")
                SupportedAppDescr+=("Logarr" "Self-hosted, single-page, log consolidation tool" "${APPONOFF}")
                ;;
            "MONITORR")
                SupportedAppDescr+=("Monitorr" "Webfront to live display the status of any webapp or service" "${APPONOFF}")
                ;;
            "MUXIMUX")
                SupportedAppDescr+=("Muximux" "A lightweight way to manage your HTPC" "${APPONOFF}")
                ;;
            "NZBGET")
                SupportedAppDescr+=("NZBGet" "NZB Newsgrabber / Downloader" "${APPONOFF}")
                ;;
            "OMBI")
                SupportedAppDescr+=("Ombi" "Allow your users to Request Movies, TV Shows and Albums" "${APPONOFF}")
                ;;
            "ORGANIZR")
                SupportedAppDescr+=("Organizr" "HTPC/Homelab Services Organizer" "${APPONOFF}")
                ;;
            "PLEX")
                SupportedAppDescr+=("Plex" "Organizes all of your video, music and photo collections" "${APPONOFF}")
                ;;
            "PLEXREQUESTS")
                SupportedAppDescr+=("Plex Requests" "Automated way for users to request new content for Plex" "${APPONOFF}")
                ;;
            "PORTAINER")
                SupportedAppDescr+=("Portainer" "Simple management UI for Docker" "${APPONOFF}")
                ;;
            "RADARR")
                SupportedAppDescr+=("Radarr" "Automatically download movies via Usenet and BitTorrent" "${APPONOFF}")
                ;;
            "RUTORRENT")
                SupportedAppDescr+=("ruTorrent" "Web front-end for rTorrent" "${APPONOFF}")
                ;;
            "SABNZBD")
                SupportedAppDescr+=("SABnzbd" "NZB Newsgrabber / Downloader" "${APPONOFF}")
                ;;
            "SICKRAGE")
                SupportedAppDescr+=("Sickrage" "Automatic Video Library Manager for TV Shows" "${APPONOFF}")
                ;;
            "SONARR")
                SupportedAppDescr+=("Sonarr" "Smart TV show PVR via Usenet and BitTorrent" "${APPONOFF}")
                ;;
            "SYNCTHING")
                SupportedAppDescr+=("Syncthing" "Open-source peer-to-peer file synchronization" "${APPONOFF}")
                ;;
            "TAUTULLI")
                SupportedAppDescr+=("Tautulli" "Monitoring and tracking tool for Plex Media Server" "${APPONOFF}")
                ;;
            "TRANSMISSION")
                SupportedAppDescr+=("Transmission" "Fast, easy, and free BitTorrent client" "${APPONOFF}")
                ;;
            "UNIFI")
                SupportedAppDescr+=("Unifi" "Controller software for wireless networks" "${APPONOFF}")
                ;;
            "WATCHER")
                SupportedAppDescr+=("Watcher" "Automated movie NZB & Torrent searcher and snatcher" "${APPONOFF}")
                ;;
            "WATCHTOWER")
                SupportedAppDescr+=("Watchtower" "Automatically update running Docker containers" "${APPONOFF}")
                ;;
            *)
                warning "WARNING ${APPNAME} APP DESCRIPTION NOT FOUND"
                SupportedAppDescr+=("${APPNAME}" "Description not found" "${APPONOFF}")
                ;;
        esac
    }

    SupportedAppDescr=()
    while IFS= read -r line; do
        local APPNAME
        APPNAME=${line/_ENABLED=*/}
        local FILENAME
        FILENAME=${APPNAME,,}
        if [[ -d ${SCRIPTPATH}/compose/.apps/${FILENAME}/ ]]; then
            if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml ]]; then
                if [[ ${ARCH} == "arm64" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.arm64.yml ]]; then
                        GetMenuItem "${APPNAME}"
                    elif [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                        GetMenuItem "${APPNAME}"
                    fi
                fi
                if [[ ${ARCH} == "armhf" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                        GetMenuItem "${APPNAME}"
                    fi
                fi
                if [[ ${ARCH} == "amd64" ]]; then
                    GetMenuItem "${APPNAME}"
                fi
            fi
        fi
    done < <(grep '_ENABLED=' < "${SCRIPTPATH}/compose/.env")
}
