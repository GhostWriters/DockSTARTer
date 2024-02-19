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
services:
  proxymanager:
    image: jc21/nginx-proxy-manager:latest
    container_name: proxymanager
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    restart: unless-stopped
    volumes:
      - ${DOCKER_VOLUME_CONFIG}/proxymanager/config.json:/app/config/config.json
      - ${DOCKER_VOLUME_CONFIG}/proxymanager/data:/data
      - ${DOCKER_VOLUME_CONFIG}/proxymanager/letsencrypt:/etc/letsencrypt
      - ${DOCKER_VOLUME_STORAGE}:/storage
```
