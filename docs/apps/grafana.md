# Grafana

[![Docker Pulls](https://img.shields.io/docker/pulls/grafana/grafana?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/grafana/grafana)
[![GitHub Stars](https://img.shields.io/github/stars/grafana/grafana?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/grafana/grafana)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/grafana)

## Description

[Grafana](https://grafana.com/) is an open-source platform for monitoring and observability. Grafana allows you to query, visualize, alert on and understand your metrics no matter where they are stored.

## Install/Setup

### Permissions Problems

If you see the following error:

>mkdir: cannot create directory '/var/lib/grafana/plugins': Permission denied,
GF_PATHS_DATA='/var/lib/grafana' is not writable.

Run the following command to fix it:

```bash
sudo chown -R $USER:$USER ~/.config/appdata/grafana
```
