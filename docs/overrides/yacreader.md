# YACReader Server

[YACReader](https://www.yacreader.com/) is for Reading, Browsing, And Managing your Digital Comics Collection.

The GIT Repository for YACReader Server is located at [https://github.com/josetesan/yacreaderlibrary-server-docker](https://github.com/josetesan/yacreaderlibrary-server-docker)
The Docker Hub link for YACReader Server is
[https://hub.docker.com/r/muallin/yacreaderlibrary-server-docker](https://hub.docker.com/r/muallin/yacreaderlibrary-server-docker)

## ENV Variable

The YACReader Server Override uses Variables that you will need to update your `.env` with the below example.

```ENV
YACREADER_PORT_8080=8080
```

## Example Docker Compose Override

```yaml
version: "3.4"  # this must match the version in docker-compose.yml
services:
  YACReaderLibraryServer:
    image: muallin/yacreaderlibrary-server-docker
    container_name: yacreader-server
    restart: unless-stopped
    volumes:
      - ${DOCKERCONFDIR}/YACReaderLibraryServer:/config
      - ${DOCKERSHAREDDIR}:/shared
      - ${MEDIADIR_COMICS}:/comics
      - ${DOWNLOADSDIR}:/downloads
    ports:
      - "${YACREADER_PORT_8080}:8080"
```
