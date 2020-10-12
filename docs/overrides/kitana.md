# kitana

[![Docker Pulls](https://img.shields.io/docker/pulls/pannal/kitana?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/pannal/kitana)
[![GitHub Stars](https://img.shields.io/github/stars/pannal/kitana?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/pannal/kitana)

## Description

[kitana](https://github.com/pannal/kitana) is a responsive Plex plugin web frontend.

## Install/Setup

### Example Docker Compose Override

```yaml
version: "3.4"
services:

  kitana:
    container_name: kitana
    environment:
    - TZ=${TZ}
    image: pannal/kitana
    logging:
      driver: json-file
      options:
        max-file: ${DOCKERLOGGING_MAXFILE}
        max-size: ${DOCKERLOGGING_MAXSIZE}
    ports:
    - 31337:31337
    restart: unless-stopped
    volumes:
    - /etc/localtime:/etc/localtime:ro
    - ${DOCKERCONFDIR}/kitana:/app/data
    - ${DOCKERSTORAGEDIR}:/storage
```
