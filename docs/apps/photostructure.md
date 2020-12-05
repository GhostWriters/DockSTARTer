# PhotoStructure

[![Docker Pulls](https://img.shields.io/docker/pulls/photostructure/server?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/photostructure/server)
[![GitHub Stars](https://img.shields.io/github/stars/photostructure/photostructure-for-servers?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/photostructure/photostructure-for-servers)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/photostructure)

## Description

[PhotoStructure](https://photostructure.com/) is your new home for all your photos & videos.

## Install/Setup

There are a few directories that get mounted on PhotoStructure that require a bit of a breakdown per the developer.

`/ps/tmp` is PhotoStructure’s “scratch” directory.

* It **must** be on a local disk, preferably an SSD.
* This volume should have at least 16-32 GB free.

If your PhotoStructure library is hosted somewhere over the network, then you must set the `.env` variable `PS_FORCE_LOCAL_DB_REPLICA` to a `1`. It currently defaults to a `0`.
