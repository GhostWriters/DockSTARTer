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
                "AIRDCPP")
                    APPLIST+=("AirdcPP" "Client for Advanced Direct Connect and Direct Connect networks" "${APPONOFF}")
                    ;;
                "AIRSONIC")
                    APPLIST+=("Airsonic" "Web-based media streamer providing ubiquitious access to your music" "${APPONOFF}")
                    ;;
                "BAZARR")
                    APPLIST+=("Bazarr" "Companion to Sonarr to manage and download subtitles" "${APPONOFF}")
                    ;;
                "CALIBREWEB")
                    APPLIST+=("CalibreWeb" "Web app for browsing, reading and downloading eBooks" "${APPONOFF}")
                    ;;
                "COUCHPOTATO")
                    APPLIST+=("Couchpotato" "Movies PVR Client" "${APPONOFF}")
                    ;;
                "DDCLIENT")
                    APPLIST+=("DDClient" "Update dynamic DNS entries" "${APPONOFF}")
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
                "GLANCES")
                    APPLIST+=("Glances" "Cross-platform system monitoring tool" "${APPONOFF}")
                    ;;
                "GUACAMOLE")
                    APPLIST+=("Guacamole" "Web application that provides access to desktop environments using remote desktop protocols" "${APPONOFF}")
                    ;;
                "HEADPHONES")
                    APPLIST+=("Headphones" "Music PVR Client" "${APPONOFF}")
                    ;;
                "HEIMDALL")
                    APPLIST+=("Heimdall" "Application dashboard and launcher" "${APPONOFF}")
                    ;;
                "HOMEASSISTANT")
                    APPLIST+=("HomeAssistant" "Track and control all devices at home and automate control" "${APPONOFF}")
                    ;;
                "HTPCMANAGER")
                    APPLIST+=("HTPCManager" "Front end for many htpc related applications" "${APPONOFF}")
                    ;;
                "HYDRA2")
                    APPLIST+=("Hydra2" "Meta search for NZB indexers" "${APPONOFF}")
                    ;;
                "JACKETT")
                    APPLIST+=("Jackett" "API Support for your favorite private trackers" "${APPONOFF}")
                    ;;
                "LAZYLIBRARIAN")
                    APPLIST+=("LazyLibrarian" "Book PVR Client" "${APPONOFF}")
                    ;;
                "LETSENCRYPT")
                    APPLIST+=("LetsEncrypt" "Certificate authority that provides free X.509 certificates" "${APPONOFF}")
                    ;;
                "LIDARR")
                    APPLIST+=("Lidarr" "Music download manager for Usenet and BitTorrent users" "${APPONOFF}")
                    ;;
                "LOGARR")
                    APPLIST+=("Logarr" "Self-hosted, single-page, log consolidation tool" "${APPONOFF}")
                    ;;
                "MARIADB")
                    APPLIST+=("MariaDB" "One of the most popular database servers" "${APPONOFF}")
                    ;;
                "MCMYADMIN2")
                    APPLIST+=("McMyAdmin2" "Minecraft with a web control panel and admin console" "${APPONOFF}")
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
                "NEXTCLOUD")
                    APPLIST+=("Nextcloud" "Gives you access to all your files wherever you are" "${APPONOFF}")
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
                "PHPMYADMIN")
                    APPLIST+=("phpMyAdmin" "A web interface for MySQL and MariaDB" "${APPONOFF}")
                    ;;
                "PIHOLE")
                    APPLIST+=("PiHole" "A black hole for internet advertisements" "${APPONOFF}")
                    ;;
                "PLEX")
                    APPLIST+=("Plex" "Organizes all of your video, music and photo collections" "${APPONOFF}")
                    ;;
                "PLEXREQUESTS")
                    APPLIST+=("PlexRequests" "Automated way for users to request new content for Plex" "${APPONOFF}")
                    ;;
                "PORTAINER")
                    APPLIST+=("Portainer" "Simple management UI for Docker" "${APPONOFF}")
                    ;;
                "PORTAINERAGENT")
                    APPLIST+=("PortainerAgent" "An agent used to manage all the resources in a Swarm cluster" "${APPONOFF}")
                    ;;
                "QBITTORRENT")
                    APPLIST+=("qBittorrent" "Cross-platform free and open-source BitTorrent client" "${APPONOFF}")
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
                "SABNZBDVPN")
                    APPLIST+=("SABnzbdVPN" "SABnzbd, OpenVPN and Privoxy" "${APPONOFF}")
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
                "THELOUNGE")
                    APPLIST+=("TheLounge" "Web IRC client that you host on your own server" "${APPONOFF}")
                    ;;
                "TRANSMISSION")
                    APPLIST+=("Transmission" "Fast, easy, and free BitTorrent client" "${APPONOFF}")
                    ;;
                "TRANSMISSIONVPN")
                    APPLIST+=("TransmissionVPN" "Transmission, WebUI and OpenVPN" "${APPONOFF}")
                    ;;
                "UBOOQUITY")
                    APPLIST+=("Ubooquity" "Home server for your comics and ebooks" "${APPONOFF}")
                    ;;
                "UNIFI")
                    APPLIST+=("Unifi" "Controller software for wireless networks" "${APPONOFF}")
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
        SELECTEDAPPS=$(whiptail --fb --clear --title "DockSTARTer" --separate-output --checklist "Choose which apps you would like to install:" 0 0 0 "${APPLIST[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
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
                local APPNAME
                APPNAME=${line^^}
                run_script 'env_set' "${APPNAME}_ENABLED" true
            done < <(echo "${SELECTEDAPPS}")
        fi
    fi
}
