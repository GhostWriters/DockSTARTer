# autobrr

[![GitHub Downloads](https://img.shields.io/github/downloads/autobrr/autobrr/total?color=607D8B&logo=github&style=flat-square)](https://hub.docker.com/r/linuxserver/airsonic-advanced)
[![GitHub Stars](https://img.shields.io/github/stars/autobrr/autobrr?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/autobrr/autobrr)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/.apps/autobrr)

## Description

[autobrr](https://github.com/autobrr/autobrr) is the modern download automation tool for torrents and usenet. With inspiration and ideas from tools like trackarr, autodl-irssi and flexget we built one tool that can do it all, and then some.

## Install/Setup

When installing the autobrr container, the installer will install under the
`appdata` directory as the root user and you will see errors as such:

> error creating file: "open /config/config.toml: permission denied"

However once it is installed you can change the owner/group of it to whatever is
required. Run the following command to fix it:

```bash
sudo chown -R $USER:$USER ~/.config/appdata/autobrr
```

Restart your container by running:

```bash
docker restart autobrr
```

For other issues please refer to the container [Application Setup](https://autobrr.com/installation/docker) documentation.
