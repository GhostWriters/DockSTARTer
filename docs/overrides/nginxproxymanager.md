# Nginx Proxy Manager

[![Docker Pulls](https://img.shields.io/docker/pulls/jc21/nginx-proxy-manager?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/jc21/nginx-proxy-manager)
[![GitHub Stars](https://img.shields.io/github/stars/jc21/nginx-proxy-manager?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/jc21/nginx-proxy-manager)

## Description

[Nginx Proxy Manager](https://nginxproxymanager.com/) is a Docker container for managing Nginx proxy hosts and SSL Certificates with a simple, powerful interface.

## Install/Setup

### Config File

Nginx Proxy Manager requires a Configuration file named `config.json`. This file needs to be in the appdata folder for NPM before it is started.

```json
{
  "database": {
    "engine": "mysql",
    "host": "db",
    "name": "npm",
    "user": "npm",
    "password": "npm",
    "port": "3306"
  }
}
```

### Example Docker Compose Override

```yaml
version: "3.4"
services:

  proxymanager:
    image: jc21/nginx-proxy-manager:latest
    container_name: proxymanager
    logging:
      driver: json-file
      options:
        max-file: ${DOCKERLOGGING_MAXFILE}
        max-size: ${DOCKERLOGGING_MAXSIZE}
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    restart: unless-stopped
    volumes:
      - ${DOCKERCONFDIR}/proxymanager/config.json:/app/config/config.json
      - ${DOCKERCONFDIR}/proxymanager/data:/data
      - ${DOCKERCONFDIR}/proxymanager/letsencrypt:/etc/letsencrypt
      - ${DOCKERSTORAGEDIR}:/storage
```
