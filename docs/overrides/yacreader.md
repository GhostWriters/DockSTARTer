# YACReader Server

[![Docker Pulls](https://img.shields.io/docker/pulls/muallin/yacreaderlibrary-server-docker?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/muallin/yacreaderlibrary-server-docker)
[![GitHub Stars](https://img.shields.io/github/stars/josetesan/yacreaderlibrary-server-docker?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/josetesan/yacreaderlibrary-server-docker)

## Description

[YACReader](https://www.yacreader.com/) is for Reading, Browsing, And Managing your Digital Comics Collection.

## Example Docker Compose Override

```yaml
version: "3.4"  # this must match the version in docker-compose.yml
services:

  yacreaderlibraryserver:
    image: muallin/yacreaderlibrary-server-docker
    container_name: yacreaderlibraryserver
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKERCONFDIR}/yacreaderlibraryserver:/config
      - ${DOCKERSTORAGEDIR}:/storage
    ports:
      - "8080:8080"
```
