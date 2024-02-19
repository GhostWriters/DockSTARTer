# Dashmachine

[![Docker Pulls](https://img.shields.io/docker/pulls/rmountjoy/dashmachine?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/rmountjoy/dashmachine)
[![GitHub Stars](https://img.shields.io/github/stars/rmountjoy92/dashmachine?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/rmountjoy92/DashMachine)

## Description

[Dashmachine](https://github.com/rmountjoy92/DashMachine) is a web application bookmark dashboard, with fun features.

## Install/Setup

### Example Docker Compose Override

```yaml
services:
  dashmachine:
    container_name: dashmachine
    hostname: ${DOCKER_HOSTNAME}
    image: rmountjoy/dashmachine:latest
    ports:
      - 5002:5000
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKER_VOLUME_CONFIG}/dashmachine:/DashMachine/dashmachine/user_data
      - ${DOCKER_VOLUME_STORAGE}:/storage
```
