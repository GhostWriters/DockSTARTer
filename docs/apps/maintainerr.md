# Maintainerr

[![Docker Pulls](https://img.shields.io/docker/pulls/jorenn92/maintainerr?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/jorenn92/maintainerr)
[![GitHub Stars](https://img.shields.io/github/stars/jorenn92/Maintainerr?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/jorenn92/Maintainerr)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/.apps/maintainerr)

## Description

[Maintainerr](https://github.com/jorenn92/Maintainerr) is an automated media management tool designed to help users free up storage space on their media servers by identifying and removing unwatched or unwanted content. It integrates with platforms like Plex, Overseerr, Radarr, Sonarr, Jellyseerr, and Tautulli, allowing users to set customizable rules for detecting media that is taking up space but not being used. Maintainerr can automatically create collections of such media, display them on the Plex home screen for a specified period before deletion, and then remove or unmonitor the files from your server. The application aims to simplify server maintenance by automating the cleanup process, making it easy to reclaim disk space without manual intervention.

## Install/Setup

When installing the Maintainerr container, it will create its data directory in `appdata` as the root user. If you see errors like:

> Could not create or access (files in) the data directory. Please make sure the necessary permissions are set

You will need to change the ownership of the directory to your user account. To do this, run:

```bash
sudo chown -R $USER:$USER ~/.config/appdata/Maintainerr
```

Restart your container by running:

```bash
docker restart Maintainerr
```

Setting the correct ownership will let you edit the files as needed and will help ensure the application runs properly, without permission issues.

If you need further assistance setting up this application, please visit the official
[GitHub repository](https://github.com/jorenn92/Maintainerr) or our
[support page](https://dockstarter.com/basics/support/).
