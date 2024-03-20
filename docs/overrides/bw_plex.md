# bw_plex

[![Docker Pulls](https://img.shields.io/docker/pulls/hellowlol/bw_plex?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/hellowlol/bw_plex)
[![GitHub Stars](https://img.shields.io/github/stars/Hellowlol/bw_plex?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/Hellowlol/bw_plex)

## Description

[bw_plex](https://github.com/Hellowlol/bw_plex) is a tool for skipping intro and outro for plex.

## Install/Setup

### ENV Variable

The bw_plex override uses Variables that you will need to update your `.env` with the below example.

```ENV
BW_PLEX_TOKEN=your_plex_x_token
BW_PLEX_URL=http://plex:32400
```

### Example Docker Compose Override

```yaml
services:
  bw_plex:
    image: hellowlol/bw_plex:latest
    container_name: bw_plex
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKER_VOLUME_CONFIG}/bw_plex:/config
      - ${DOCKER_VOLUME_STORAGE}:/storage
    command: bw_plex --url ${BW_PLEX_URL} -t ${BW_PLEX_TOKEN} -df /config watch
```
