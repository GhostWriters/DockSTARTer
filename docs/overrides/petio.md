# Petio

[![Docker Pulls](https://img.shields.io/docker/pulls/hotio/petio?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/hotio/petio)
[![GitHub Stars](https://img.shields.io/github/stars/hotio/petio?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/hotio/petio)

## Description

[Petio](https://petio.tv/) is a third party companion app available to Plex server owners to allow their users to request, review and discover content. The app is built to appear instantly familiar and intuitive to even the most tech-agnostic users. Petio will help you manage requests from your users, connect to other third party apps such as Sonarr and Radarr, notify users when content is available and track request progress. Petio also allows users to discover media both on and off your server, quickly and easily find related content and review to leave their opinion for other users.

## Install/Setup

### Example Docker Compose Override

```yaml
services:

  petio:
    container_name: petio
    environment:
      - TZ=${TZ}
    hostname: ${DOCKERHOSTNAME}
    image: ghcr.io/hotio/petio
    logging:
      driver: json-file
      options:
        max-file: ${DOCKERLOGGING_MAXFILE}
        max-size: ${DOCKERLOGGING_MAXSIZE}
    ports:
      - 7777:7777
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKERCONFDIR}/petio:/config
  mongo:
    container_name: mongo
    environment:
      - TZ=${TZ}
    hostname: ${DOCKERHOSTNAME}
    image: mongo
    logging:
      driver: json-file
      options:
        max-file: ${DOCKERLOGGING_MAXFILE}
        max-size: ${DOCKERLOGGING_MAXSIZE}
    ports:
      - 27017:27017
    restart: unless-stopped
    user: ${PUID}:${PGID}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKERCONFDIR}/mongo:/data/configdb
      - ${DOCKERCONFDIR}/mongo/db:/data/db
```
