# Wizarr

[![GitHub Downloads](https://img.shields.io/github/downloads/Wizarrrr/wizarr/total?color=607D8B&label=github%20downloads&logo=github&style=flat-square)](https://github.com/Wizarrrr/wizarr)
[![GitHub Stars](https://img.shields.io/github/stars/Wizarrrr/wizarr?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/Wizarrrr/wizarr)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/wizarr)

## Description

[Wizarr](https://docs.wizarr.dev/) is a automatic user invitation system for Plex, Jellyfin and Emby. Create a unique link and share it to a user and they will automatically be invited to your media Server! They will even be guided to download the client and instructions on how to use your requests software!

## Install/Setup

When installing the Wizarr container, the installer will install under the `appdata` directory as the root user and you will see errors as such:

> PermissionError: [Errno 13] Permission denied: './database/sessions'

However once it is installed you can change the owner/group of it to whatever is
required. Run the following command to fix it:

```bash
sudo chown -R $USER:$USER ~/.config/appdata/wizarr
```

Restart your container by running:

```bash
docker restart wizarr
```

If you need additional assistance setting up this application please visit the [official documentation](https://docs.wizarr.dev/getting-started/installation) or our [support page](https://dockstarter.com/basics/support/).

## Reverse Proxy

To set up in a reverse proxy (SWAG/Traefik/NPM/etc.) see the instructions listed [in the documentation.](https://docs.wizarr.dev/getting-started/reverse-proxy) Wizarr is only designed to work as a subdomain application, not as a subfolder.
