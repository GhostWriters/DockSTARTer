# Tdarr

[![Docker Pulls](https://img.shields.io/docker/pulls/haveagitgat/tdarr?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/haveagitgat/tdarr)
[![GitHub Stars](https://img.shields.io/github/stars/haveagitgat/tdarr?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/haveagitgat/tdarr)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/compose/.apps/tdarr)

## Description

[Tdarr](https://github.com/haveagitgat/tdarr) is a cross-platform, distributed transcoding system which is broken up into multiple modules.

## Install/Setup

When installing the Tdarr container, the installer will install under the
`appdata` directory as the root user and you will see errors as such:

> - Starting database mongodb
>
> ...fail

Permissions are likely not set correctly on your `TDARR_DB` variable location,
run the following:

```bash
sudo chown -R $USER:$USER /path/to/location
```

Restart your container by running:

```bash
docker restart tdarr
```
