# HTTP Server

[![Docker Pulls](https://img.shields.io/docker/pulls/patrickdappollonio/docker-http-server?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/patrickdappollonio/docker-http-server)
[![GitHub Stars](https://img.shields.io/github/stars/patrickdappollonio/http-server?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com//patrickdappollonio/http-server)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/.apps/httpserver)

## Description

[http-server](https://github.com/patrickdappollonio/http-server) is a simple binary to provide a static http server from a given folder.

## Install/Setup

### .env.app.httpserver

The variable `FILE_SERVER_COLOR_SET` can be modified to use any of the colors listed on [here](https://getmdl.io/customize/index.html).

Whenever you select a color combination, you will get a link at the bottom of the page. The link will include the color towards the end of the link:

> `<link rel="stylesheet" href="https://code.getmdl.io/1.3.0/material.indigo-pink.min.css" />`

What you care about is the bit that says `indigo-red` or `indigo-pink`. That's the color you will set in variable and run the following command to apply any changes:

```bash
ds -c up httpserver
```
