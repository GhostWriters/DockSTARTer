# Bazarr

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/bazarr?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/bazarr)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-bazarr?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-bazarr)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/bazarr)

## Description

[Bazarr](https://www.bazarr.media/) is a companion application to Sonarr and Radarr. It can manage and download subtitles based on your requirements. You define your preferences by TV show or movie and Bazarr takes care of everything for you.

## Install/Setup

By default, the DockSTARTer configuration of Bazarr will map to the following volumes:

```yaml
- ${DOCKER_VOLUME_STORAGE}:/storage
```

If you have any media outside of those locations, you'll need to create an override using [override](https://dockstarter.com/overrides/introduction) specifically for those volumes.
