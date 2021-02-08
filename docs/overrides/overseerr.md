# Overseerr

[![Docker Pulls](https://img.shields.io/docker/pulls/hotio/overseerr?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/hotio/overseerr)
[![GitHub Stars](https://img.shields.io/github/stars/hotio/overseerr?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/Cloudbox/autoscan)

## Description

[Overseerr](https://hotio.dev/containers/overseerr/) is a application for managing requests for your media library. It integrates with your existing services such as Sonarr, Radarr and Plex! (Like Ombi)

## Install/Setup

### Example Docker Compose Override

```yaml
  overseerr:
    container_name: overseerr
    image: ghcr.io/hotio/overseerr
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-file: ${DOCKERLOGGING_MAXFILE}
        max-size: ${DOCKERLOGGING_MAXSIZE}
    ports:
      - 5055:5055
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - UMASK=002
      - TZ=${TZ}
      - ARGS
    volumes:
      - ${DOCKERCONFDIR}/overseerr:/config
      - ${DOCKERSTORAGEDIR}:/storage
```
