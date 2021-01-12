# Firefly III

[![Docker Pulls](https://img.shields.io/docker/pulls/jc5x/firefly-iii?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/jc5x/firefly-iii)
[![GitHub Stars](https://img.shields.io/github/stars/firefly-iii/docker?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/firefly-iii/docker)

## Description

[Firefly III](https://github.com/firefly-iii/firefly-iii) is a personal finances manager.

## Install/Setup

### Example Docker Compose Override

```yaml
version: "3.4"
services:

  fireflyiii:
    container_name: fireflyiii
    environment:
      - APP_KEY=CHANGEME_32_CHARS
      - APP_URL=https://fireflyiii.mydomain.com
      - DB_CONNECTION=mysql
      - DB_DATABASE=fireflyiii_db
      - DB_HOST=mariadb
      - DB_PASSWORD=fireflyiii_password
      - DB_PORT=3306
      - DB_USERNAME=fireflyiii_user
      - TRUSTED_PROXIES=**
      - TZ=${TZ}
    hostname: ${DOCKERHOSTNAME}
    image: jc5x/firefly-iii
    logging:
      driver: json-file
      options:
        max-file: ${DOCKERLOGGING_MAXFILE}
        max-size: ${DOCKERLOGGING_MAXSIZE}
    ports:
      - 8001:8080
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKERCONFDIR}/fireflyiii/export:/var/www/firefly-iii/storage/export
      - ${DOCKERCONFDIR}/fireflyiii/upload:/var/www/firefly-iii/storage/upload
      - ${DOCKERSTORAGEDIR}:/storage
```
