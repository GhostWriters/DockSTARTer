# Fail2ban

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/fail2ban?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/fail2ban)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-fail2ban?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-fail2ban)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/compose/.apps/fail2ban)

## Description

[Fail2ban](https://www.fail2ban.org/) is a daemon to ban hosts that cause multiple authentication errors.

## Install/Setup

Please read the [Application Setup](https://github.com/linuxserver/docker-fail2ban#application-setup) section of the container documentation.

This container runs with special permissions `NET_ADMIN` and `NET_RAW` and runs in `host` network mode by default. These configurations allow Fail2ban to perform bans at the host level, rather than only banning from inside the docker container.

This container requires an [override](../overrides/) to add additional log paths for other applications.

Example:

```yaml
services:
  fail2ban:
    volumes:
      - "${DOCKER_VOLUME_CONFIG}/filebrowser/filebrowser.log:/remotelogs/filebrowser/filebrowser.log:ro"
      - "${DOCKER_VOLUME_CONFIG}/swag/log/nginx:/remotelogs/nginx:ro"
```
