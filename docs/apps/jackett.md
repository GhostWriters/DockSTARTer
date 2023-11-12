# Jackett

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/jackett?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/jackett)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-jackett?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-jackett)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/jackett)

## Description

[Jackett](https://github.com/Jackett/Jackett) works as a proxy server: it
translates queries from apps (Sonarr, SickRage, CouchPotato, Mylar, etc) into
tracker-site-specific http queries, parses the html response, then sends results
back to the requesting software. This allows for getting recent uploads (like
RSS) and performing searches. Jackett is a single repository of maintained
indexer scraping & translation logic - removing the burden from other apps.

## Install/Setup

This application does not have any specific setup instructions documented. If
you need assistance setting up this application please visit our
[support page](https://dockstarter.com/basics/support/).

## Configuring VPN tunnel

When attempting to use private trackers the address which requested the .torrent file must also be the address that initiates the download. Often this is an issue if you have your torrent downloader behind a VPN while the Jackett instance is not behind it.

To solve this issue:

- Enable the Privoxy option on the associated Torrent+VPN combination you choose.
- Inside the Jackett webui, set proxy type to `HTTP`
- Set Proxy URL to `servicename` example: `rtorrentvpn`
- Set Proxy port to `8118`
