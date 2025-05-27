# Komga

[![Docker Pulls](https://img.shields.io/docker/pulls/gotson/komga?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/gotson/komga)
[![GitHub Stars](https://img.shields.io/github/stars/gotson/komga?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/gotson/komga)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/komga)

## Description

[Komga](https://komga.org) is a media server for your comics, mangas, BDs and magazines.

## Install/Setup

If you cannot access the web interface after installing, check if the app's directory has the right owner. You can do that by running the command `ls -al ~/.config/appdata` and comparing the owner of the `komga` directory with the other directories. 

If the owner of `~/.config/appdata/komga` is `root` or anything else different than the standard dockstarter user, you will need to manually change user/group ownership.

### 1. Change the owner/group of `~/.config/appdata/komga`.

If the owner should be the same as the one you are logged in with, run the following command:

`sudo chown -R $USER:$USER ~/.config/appdata/komga`

Alternatively, replace `$USER:$USER` with the default user/group for dockstarter.

### 2. Restart the komga container

`docker restart komga`

At this point you should be able to access the web interface.

If you need assistance setting up this application please visit our [support page](https://dockstarter.com/basics/support/).
