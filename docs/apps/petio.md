# Petio

[![Docker Pulls](https://img.shields.io/docker/pulls/hotio/petio?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/petio-team/petio)
[![GitHub Stars](https://img.shields.io/github/stars/hotio/petio?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/petio-team/petio)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/petio)

## Description

[Petio](https://petio.tv/) is a third party companion app available to Plex server owners to allow their users to request, review and discover content. The app is built to appear instantly familiar and intuitive to even the most tech-agnostic users. Petio will help you manage requests from your users, connect to other third party apps such as Sonarr and Radarr, notify users when content is available and track request progress. Petio also allows users to discover media both on and off your server, quickly and easily find related content and review to leave their opinion for other users.

## Install/Setup

This container requires a mongodb instance that is not included in DockSTARTer. You can add mongodb to your override using the example below.

### Example Docker Compose Override

```yaml
services:
  mongo:
    container_name: mongo
    environment:
      - TZ=${TZ}
    hostname: ${DOCKER_HOSTNAME}
    image: mongo:4.4
    ports:
      - 27017:27017
    restart: unless-stopped
    user: ${PUID}:${PGID}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKER_VOLUME_CONFIG}/mongo:/data/configdb
      - ${DOCKER_VOLUME_CONFIG}/mongo/db:/data/db
```
