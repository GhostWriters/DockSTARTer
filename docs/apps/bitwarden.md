# Bitwarden

[![Docker Pulls](https://img.shields.io/docker/pulls/vaultwarden/server?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/vaultwarden/server)
[![GitHub Stars](https://img.shields.io/github/stars/dani-garcia/vaultwarden?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/dani-garcia/vaultwarden)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/bitwarden)

## Description

[Bitwarden](https://bitwarden.com/) is a free and open-source password
management service that stores sensitive information such as website credentials
in an encrypted vault.

[Vaultwarden](https://github.com/dani-garcia/vaultwarden) is an alternative implementation of the Bitwarden server API written in Rust and compatible with upstream [upstream Bitwarden clients](https://bitwarden.com/#download), perfect for self-hosted deployment where running the official resource-heavy service might not be ideal.

DockSTARTer uses the Vaultwarden image to create a Bitwarden container.

## Install/Setup

When installing the Bitwarden container, the installer will install under
`appdata` directory as the root user, however once it is installed you can
change the owner/group of it to whatever is required

Run the below command from a terminal to change the permissions if required:

```bash
sudo chown -R $USER:$USER ~/.config/appdata/bitwarden
```

Restart your container by running:

```bash
docker restart bitwarden
```

Having the owner group change will allow you to edit the files if required
without running into permission issues.
