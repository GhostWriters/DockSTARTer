# Homer

[![Docker Pulls](https://img.shields.io/docker/pulls/b4bz/homer?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/b4bz/homer)
[![GitHub Stars](https://img.shields.io/github/stars/bastienwirtz/homer?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/bastienwirtz/homer)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/homer)

## Description

[Homer](https://github.com/bastienwirtz/homer) is a dead simple static HOMepage for your servER to keep your services on hand, from a simple yaml configuration file.

## Install/Setup

Be sure to read the [app specific documentation](https://github.com/bastienwirtz/homer) on github as the environment variables below are an extension of those explained in the documentation.

Note that your configuration files and homer assets are located in `${DOCKERCONFDIR}/homer`

### Environment Variables

#### HOMER_INIT_ASSETS

`1` (default) Install example configuration file & assets (favicons, ...) to help you get started.

`0` Don't install assets. Use existing files. This is the suggested value after you first launch homer and assets are installed.

#### HOMER_SUBFOLDER

(default: `''`) If you would like to host Homer in a subfolder, (ex: http://my-domain/homer), set this to the subfolder path (ex /homer).
