#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

menu_app_helper() {
    GetMenuItem() {
        local APPNAME
        APPNAME="${1}"
        case "${APPNAME}" in
            "bazarr")
                SupportedAppDescr+=("Bazarr" "Companion to Sonarr to manage and download subtitles" "off") ;;
            "couchpotato")
                SupportedAppDescr+=("Couchpotato" "Movies PVR Client" "off") ;;
            "deluge")
                SupportedAppDescr+=("Deluge" "Lightweight, Full-featured BitTorrent client" "off") ;;
            "duckdns")
                SupportedAppDescr+=("DuckDNS" "free service which will point a DNS to an IP of your choice" "off") ;;
            "duplicati")
                SupportedAppDescr+=("Duplicati" "Backup software to store backups online with strong encryption" "off") ;;
            "emby")
                SupportedAppDescr+=("Emby" "Organize, play, and stream audio and video" "off") ;;
            "headphones")
                SupportedAppDescr+=("Headphones" "Music PVR Client" "off") ;;
            "homeassistant")
                SupportedAppDescr+=("Home Assistant" "Track and control all devices at home and automate control" "off") ;;
            "hydra2")
                SupportedAppDescr+=("Hydra2" "Meta search for NZB indexers" "off") ;;
            "jackett")
                SupportedAppDescr+=("Jackett" "API Support for your favorite private trackers" "off") ;;
            "lazylibrarian")
                SupportedAppDescr+=("Lazylibrarian" "Book PVR Client" "off") ;;
            "letsencrypt")
                SupportedAppDescr+=("Letsencrypt" "Certificate authority that provides free X.509 certificates" "off") ;;
            "lidarr")
                SupportedAppDescr+=("Lidarr" "Music download manager for Usenet and BitTorrent users" "off") ;;
            "logarr")
                SupportedAppDescr+=("Logarr" "Self-hosted, single-page, log consolidation tool") ;;
            "monitorr")
                SupportedAppDescr+=("Monitorr" "Webfront to live display the status of any webapp or service" "off") ;;
            "muximux")
                SupportedAppDescr+=("Muximux" "A lightweight way to manage your HTPC" "off") ;;
            "nzbget")
                SupportedAppDescr+=("NZBGet" "NZB Newsgrabber / Downloader" "off") ;;
            "ombi")
                SupportedAppDescr+=("Ombi" "Allow your users to Request Movies, TV Shows and Albums" "off") ;;
            "organizr")
                SupportedAppDescr+=("Organizr" "HTPC/Homelab Services Organizer" "off") ;;
            "plex")
                SupportedAppDescr+=("Plex" "Organizes all of your video, music and photo collections" "off") ;;
            "plexrequests")
                SupportedAppDescr+=("Plex Requests" "Automated way for users to request new content for Plex" "off") ;;
            "portainer")
                SupportedAppDescr+=("Portainer" "Simple management UI for Docker" "on") ;;
            "radarr")
                SupportedAppDescr+=("Radarr" "Automatically download movies via Usenet and BitTorrent" "off") ;;
            "rutorrent")
                SupportedAppDescr+=("ruTorrent" "Web front-end for rTorrent" "off") ;;
            "sabnzbd")
                SupportedAppDescr+=("SABnzbd" "NZB Newsgrabber / Downloader" "off") ;;
            "sickrage")
                SupportedAppDescr+=("Sickrage" "Automatic Video Library Manager for TV Shows" "off") ;;
            "sonarr")
                SupportedAppDescr+=("Sonarr" "Smart TV show PVR via Usenet and BitTorrent" "off") ;;
            "syncthing")
                SupportedAppDescr+=("Syncthing" "Open-source peer-to-peer file synchronization" "off") ;;
            "tautulli")
                SupportedAppDescr+=("Tautulli" "Monitoring and tracking tool for Plex Media Server" "off") ;;
            "transmission")
                SupportedAppDescr+=("Transmission" "Fast, easy, and free BitTorrent client" "off") ;;
            "unifi")
                SupportedAppDescr+=("Unifi" "Controller software for wireless networks" "off") ;;
            "watchtower")
                SupportedAppDescr+=("Watchtower" "Automatically update running Docker containers" "on") ;;
            *)
                echo -e "${RED}ERROR ${APPNAME} APP DESCRIPTION NOT FOUND${ENDCOLOR}"
                exit 1
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
