# Gluetun

[![Docker Pulls](https://img.shields.io/docker/pulls/qmcgaw/gluetun?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/qmcgaw/gluetun)
[![GitHub Stars](https://img.shields.io/github/stars/qdm12/gluetun?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/qdm12/gluetun)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/gluetun/compose/.apps/gluetun)

## Description

[Gluetun](https://github.com/qdm12/gluetun) is a VPN client in a thin Docker
container for multiple VPN providers, written in Go, and using OpenVPN or
Wireguard, DNS over TLS, with a few proxy servers built-in.

## Install/Setup

Check the [wiki](https://github.com/qdm12/gluetun/wiki) for the relevant
environment variables for your VPN provider that should be placed in
your ``docker-compose.override.yml``.

## Example

.env

```
...
TRANSMISSION_NETWORK_MODE="container:gluetun"
...
```

docker-compose.override.yml

```yml
services:
  gluetun:
    environment:
      - VPN_SERVICE_PROVIDER=mullvad
      - VPN_TYPE=wireguard
      - WIREGUARD_PRIVATE_KEY=YOUR-PRIVATE-KEY-HERE
      - WIREGUARD_ADDRESSES=YOUR-ADDRESSES-HERE
      - SERVER_CITIES=YOUR-CITIES-HERE
    ports:
      - 9091:9091
```
