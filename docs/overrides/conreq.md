# Conreq

[![Docker Pulls](https://img.shields.io/docker/pulls/roxedus/conreq?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/roxedus/conreq)
[![GitHub Stars](https://img.shields.io/github/stars/Roxedus/docker-conreq?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/Roxedus/docker-conreq)

## Description

[Conreq](https://github.com/Archmonger/Conreq) is a application for managing requests for your media library. It integrates with your existing services such as Sonarr, and Radarr! (Like Ombi)

## Install/Setup

### Example Docker Compose Override

```yaml
services:
  conreq:
    container_name: conreq
    environment:
      - PGID=${PGID}
      - PUID=${PUID}
      - TZ=${TZ}
    hostname: ${DOCKER_HOSTNAME}
    image: ghcr.io/roxedus/conreq:latest
    ports:
      - 8000:8000
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKER_VOLUME_CONFIG}/conreq:/config
      - ${DOCKER_VOLUME_STORAGE}:/storage
```
