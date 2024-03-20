# Autoscan

[![Docker Pulls](https://img.shields.io/docker/pulls/cloudb0x/autoscan?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/cloudb0x/autoscan)
[![GitHub Stars](https://img.shields.io/github/stars/Cloudbox/autoscan?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/Cloudbox/autoscan)

## Description

[Autoscan](https://github.com/Cloudbox/autoscan) replaces the default Plex and Emby behaviour for picking up changes on the file system.

## Install/Setup

### Example Docker Compose Override

```yaml
services:
  autoscan:
    image: cloudb0x/autoscan:latest
    hostname: ${DOCKER_HOSTNAME}
    ports:
      - 3030:3030
    container_name: autoscan
    environment:
      - AUTOSCAN_VERBOSITY=0
      - PGID=${PGID}
      - PUID=${PUID}
      - TZ=${TZ}
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /mnt/remote:/mnt/remote:ro
      - /opt/sa:/opt/sa
      - ${DOCKER_VOLUME_CONFIG}/autoscan:/config
      - ${DOCKER_VOLUME_STORAGE}:/storage
```
