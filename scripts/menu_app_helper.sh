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
            "bazarr")
                SupportedAppDescr+=("Bazarr" "Companion to Sonarr to manage and download subtitles" "${APPONOFF}") ;;
            "couchpotato")
                SupportedAppDescr+=("Couchpotato" "Movies PVR Client" "${APPONOFF}") ;;
            "deluge")
                SupportedAppDescr+=("Deluge" "Lightweight, Full-featured BitTorrent client" "${APPONOFF}") ;;
            "duckdns")
                SupportedAppDescr+=("DuckDNS" "free service which will point a DNS to an IP of your choice" "${APPONOFF}") ;;
            "duplicati")
                SupportedAppDescr+=("Duplicati" "Backup software to store backups online with strong encryption" "${APPONOFF}") ;;
            "emby")
                SupportedAppDescr+=("Emby" "Organize, play, and stream audio and video" "${APPONOFF}") ;;
            "headphones")
                SupportedAppDescr+=("Headphones" "Music PVR Client" "${APPONOFF}") ;;
            "homeassistant")
                SupportedAppDescr+=("Home Assistant" "Track and control all devices at home and automate control" "${APPONOFF}") ;;
            "hydra2")
                SupportedAppDescr+=("Hydra2" "Meta search for NZB indexers" "${APPONOFF}") ;;
            "jackett")
                SupportedAppDescr+=("Jackett" "API Support for your favorite private trackers" "${APPONOFF}") ;;
            "lazylibrarian")
                SupportedAppDescr+=("Lazylibrarian" "Book PVR Client" "${APPONOFF}") ;;
            "letsencrypt")
                SupportedAppDescr+=("Letsencrypt" "Certificate authority that provides free X.509 certificates" "${APPONOFF}") ;;
            "lidarr")
                SupportedAppDescr+=("Lidarr" "Music download manager for Usenet and BitTorrent users" "${APPONOFF}") ;;
            "logarr")
                SupportedAppDescr+=("Logarr" "Self-hosted, single-page, log consolidation tool" "${APPONOFF}") ;;
            "monitorr")
                SupportedAppDescr+=("Monitorr" "Webfront to live display the status of any webapp or service" "${APPONOFF}") ;;
            "muximux")
                SupportedAppDescr+=("Muximux" "A lightweight way to manage your HTPC" "${APPONOFF}") ;;
            "nzbget")
                SupportedAppDescr+=("NZBGet" "NZB Newsgrabber / Downloader" "${APPONOFF}") ;;
            "ombi")
                SupportedAppDescr+=("Ombi" "Allow your users to Request Movies, TV Shows and Albums" "${APPONOFF}") ;;
            "organizr")
                SupportedAppDescr+=("Organizr" "HTPC/Homelab Services Organizer" "${APPONOFF}") ;;
            "plex")
                SupportedAppDescr+=("Plex" "Organizes all of your video, music and photo collections" "${APPONOFF}") ;;
            "plexrequests")
                SupportedAppDescr+=("Plex Requests" "Automated way for users to request new content for Plex" "${APPONOFF}") ;;
            "portainer")
                SupportedAppDescr+=("Portainer" "Simple management UI for Docker" "${APPONOFF}") ;;
            "radarr")
                SupportedAppDescr+=("Radarr" "Automatically download movies via Usenet and BitTorrent" "${APPONOFF}") ;;
            "rutorrent")
                SupportedAppDescr+=("ruTorrent" "Web front-end for rTorrent" "${APPONOFF}") ;;
            "sabnzbd")
                SupportedAppDescr+=("SABnzbd" "NZB Newsgrabber / Downloader" "${APPONOFF}") ;;
            "sickrage")
                SupportedAppDescr+=("Sickrage" "Automatic Video Library Manager for TV Shows" "${APPONOFF}") ;;
            "sonarr")
                SupportedAppDescr+=("Sonarr" "Smart TV show PVR via Usenet and BitTorrent" "${APPONOFF}") ;;
            "syncthing")
                SupportedAppDescr+=("Syncthing" "Open-source peer-to-peer file synchronization" "${APPONOFF}") ;;
            "tautulli")
                SupportedAppDescr+=("Tautulli" "Monitoring and tracking tool for Plex Media Server" "${APPONOFF}") ;;
            "transmission")
                SupportedAppDescr+=("Transmission" "Fast, easy, and free BitTorrent client" "${APPONOFF}") ;;
            "unifi")
                SupportedAppDescr+=("Unifi" "Controller software for wireless networks" "${APPONOFF}") ;;
            "watchtower")
                SupportedAppDescr+=("Watchtower" "Automatically update running Docker containers" "${APPONOFF}") ;;
            *)
                error "ERROR ${APPNAME} APP DESCRIPTION NOT FOUND"
                ;;
        esac
    }

    SupportedAppDescr=()
    while IFS= read -r line; do
        local APPNAME
        APPNAME=${line/_ENABLED=*/}
        APPNAME="${APPNAME,,}"
        if [[ ${ARCH} == "arm64" ]]; then
            if [[ -f ${SCRIPTPATH}/compose/.apps/${APPNAME}/${APPNAME}.arm64.yml ]]; then
                GetMenuItem "${APPNAME}"
            elif [[ -f ${SCRIPTPATH}/compose/.apps/${APPNAME}/${APPNAME}.armhf.yml ]]; then
                GetMenuItem "${APPNAME}"
            fi
        elif [[ ${ARCH} == "armhf" ]]; then
            if [[ -f ${SCRIPTPATH}/compose/.apps/${APPNAME}/${APPNAME}.armhf.yml ]]; then
                GetMenuItem "${APPNAME}"
            fi
        else
            if [[ -f ${SCRIPTPATH}/compose/.apps/${APPNAME}/${APPNAME}.yml ]]; then
                GetMenuItem "${APPNAME}"
            fi
        fi
    done < <(grep '_ENABLED=' < "${SCRIPTPATH}/compose/.env")
}
