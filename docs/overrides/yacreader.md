# YACReader Server

[![Docker Pulls](https://img.shields.io/docker/pulls/muallin/yacreaderlibrary-server-docker?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/muallin/yacreaderlibrary-server-docker)
[![GitHub Stars](https://img.shields.io/github/stars/josetesan/yacreaderlibrary-server-docker?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/josetesan/yacreaderlibrary-server-docker)

[YACReader](https://www.yacreader.com/) is for Reading, Browsing, And Managing your Digital Comics Collection.

## ENV Variable

The YACReader Server Override uses Variables that you will need to update your `.env` with the below example.

```ENV
YACREADER_PORT_8080=8080
```

### Example Docker Compose Override

```yaml
version: "3.4"  # this must match the version in docker-compose.yml
services:
  YACReaderLibraryServer:
    image: muallin/yacreaderlibrary-server-docker
    container_name: yacreader-server
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKERCONFDIR}/YACReaderLibraryServer:/config
      - ${DOCKERSTORAGEDIR}:/storage
    ports:
      - "${YACREADER_PORT_8080}:8080"
```
