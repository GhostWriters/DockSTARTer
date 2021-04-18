# Overseerr

[![Docker Pulls](https://img.shields.io/docker/pulls/hotio/overseerr?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/hotio/overseerr)
[![GitHub Stars](https://img.shields.io/github/stars/hotio/overseerr?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/hotio/overseerr)

## Description

[Overseerr](https://github.com/sct/overseerr) is a application for managing requests for your media library. It integrates with your existing services such as Sonarr, Radarr and Plex! (Like Ombi)

## Install/Setup

### Example Docker Compose Override

```yaml
services:

  overseerr:
    container_name: overseerr
    environment:
      - PGID=${PGID}
      - PUID=${PUID}
      - TZ=${TZ}
    hostname: ${DOCKERHOSTNAME}
    image: ghcr.io/hotio/overseerr
    logging:
      driver: json-file
      options:
        max-file: ${DOCKERLOGGING_MAXFILE}
        max-size: ${DOCKERLOGGING_MAXSIZE}
    ports:
      - 5055:5055
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKERCONFDIR}/overseerr:/config
      - ${DOCKERSTORAGEDIR}:/storage
```
