# Recyclarr

[![Docker Pulls](https://img.shields.io/docker/pulls/recyclarr/recyclarr?color=607D8B&label=docker%20pulls&logo=docker&style=flat-square)](https://hub.docker.com/r/recyclarr/recyclarr)
[![GitHub Stars](https://img.shields.io/github/stars/recyclarr/recyclarr?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/recyclarr/recyclarr)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/recyclarr)

## Description

[Recyclarr](https://recyclarr.dev) Recyclarr is a command-line application that will automatically synchronize recommended settings from the TRaSH guides to your Sonarr/Radarr instances. It was formerly named "Trash Updater".

## Install/Setup

When installing the Recyclarr container, the installer will install under
`appdata` directory as the root user, however once it is installed you can
change the owner/group of it to whatever is required

Run the below command from a terminal to change the permissions if required:

```bash
sudo chown -R $USER:$USER ~/.config/appdata/recyclarr
```

Restart your container by running:

```bash
docker restart recyclarr
```

Having the owner group change will allow you to edit the files if required
without running into permission issues.

This application does not have any further specific setup instructions documented. If
you need assistance setting up this application please visit our
[support page](https://dockstarter.com/basics/support/).
