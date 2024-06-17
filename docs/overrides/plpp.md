# PLPP

[![Docker Pulls](https://img.shields.io/docker/pulls/tronyx/docker-plpp?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/tronyx/docker-plpp)
[![GitHub Stars](https://img.shields.io/github/stars/christronyxyocum/docker-plpp?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://www.github.com/christronyxyocum/docker-plpp)

## Description

[PHP Library Presenter for PLEX](https://github.com/Tensai75/plpp) provides a PHP front end to simply present PLEX libraries on the web without the possibility to play or download the library items. Currently movie/home video, TV show, music and photo/picture libraries are supported.

## Install/Setup

### Example Docker Compose Override

```yaml
services:
  plpp:
    container_name: plpp
    environment:
      - PGID=${PGID}
      - PUID=${PUID}
      - TZ=${TZ}
    hostname: ${DOCKER_HOSTNAME}
    image: tronyx/docker-plpp:latest
    ports:
      - 8383:80
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKER_VOLUME_CONFIG}/plpp:/config
      - ${DOCKER_VOLUME_STORAGE}:/storage
```
