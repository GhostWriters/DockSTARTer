# Bitwarden

[![Docker Pulls](https://img.shields.io/docker/pulls/bitwardenrs/server?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/bitwardenrs/server)
[![GitHub Stars](https://img.shields.io/github/stars/dani-garcia/bitwarden_rs?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/dani-garcia/bitwarden_rs)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/bitwarden)

## Description

[Bitwarden](https://bitwarden.com/) is a free and open-source password management service that stores sensitive information such as website credentials in an encrypted vault. This is a Bitwarden server API implementation written in Rust compatible with [upstream Bitwarden clients](https://bitwarden.com/#download), perfect for self-hosted deployment where running the official resource-heavy service might not be ideal.

## Install/Setup

When installing the Bitwarden container, the installer will install under Appdata directory as the root user, however once it is installed you can change the owner/group of it to whatever is required

Run the below command (from a terminal) to change the permissions if required.

```bash
sudo chown -R owner:group ~/.config/appdata/bitwarden
```

Having the owner group change will allow you to edit the files if required without running into permission issues.
