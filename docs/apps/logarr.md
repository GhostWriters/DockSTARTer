# Logarr

[![Docker Pulls](https://img.shields.io/docker/pulls/monitorr/logarr?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/monitorr/logarr/)
[![GitHub Stars](https://img.shields.io/github/stars/monitorr/logarr?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/Monitorr/logarr)

## Description

[Logarr](https://github.com/Monitorr/logarr) is a self-hosted, single-page, log consolidation tool written in PHP.

## Install/Setup

Logarr configuration has sharing to the logs enabled by default. From within the Logarr container, this is accessible via the `/var/log/logarrlogs` path. Which is mapped to your `~/.config/appdata` path of your host machine.

For Logarr you will need to edit the `config.php` file to point to the correct log files. This file is located in the `~/.config/appdata/logarr/www/logarr/assets/` folder of your host machine.

Edit the included config to change these lines:

```json
    "Sonarr" => '/var/log/logarrlogs/sonarr/logs/sonarr.txt',
    "Radarr" => '/var/log/logarrlogs/radarr/logs/radarr.txt',
```
