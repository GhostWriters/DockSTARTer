# RustDesk

[![Docker Pulls](https://img.shields.io/docker/pulls/rustdesk/rustdesk-server?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/rustdesk/rustdesk-server)
[![GitHub Stars](https://img.shields.io/github/stars/rustdesk/rustdesk?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/rustdesk/rustdesk)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/compose/.apps/rustdesk)

## Description

[RustDesk](https://rustdesk.com) is an open-source, self-hosted TeamViewer alternative.

This uses the "S6-overlay based image" for RustDesk which ships both hbbs and hbbr in a single container.

hbbs is the RustDesk ID/Rendezvous server. hbbr is the RustDesk relay server. Both are needed for a functional RustDesk deployment.

When hbbs is first run, it will generate a public/private key pair for the clients to use. You can see this take place in the logs:

```env
INFO [src/common.rs:133] Private/public key written to id_ed25519/id_ed25519.pub
```

You can view the contents of this key by browsing to your config folder, for instance, `~/.config/appdata/rustdesk`.

## Install/Setup

This application does not have any specific setup instructions documented. If
you need assistance setting up this application please visit our
[support page](https://dockstarter.com/basics/support/).
