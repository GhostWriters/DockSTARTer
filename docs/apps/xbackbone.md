# XBackBone

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/xbackbone?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/xbackbone)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-xbackbone?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-xbackbone)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/xbackbone)

## Description

[XBackBone](<(https://sergix44.github.io/XBackBone/)>) is a simple and
lightweight PHP file manager that supports the instant sharing tool ShareX and
\*NIX systems. It supports uploading and displaying images, GIFs, video, code,
formatted text, pdf, and file downloading and uploading. Also has a web UI with
multi-user management, media gallery and search support.

## Install/Setup

When installing the XBackBone container, the installer will install under the
`appdata` directory as the root user and you will see errors as such:

```bash
Executing /opt/docker/provision/entrypoint.d/01-app.sh
PHP Fatal error:  Uncaught PDOException: SQLSTATE[HY000]
[14] unable to open database file in
/app/app/Database/DB.php:20
```

You need to update the permissions in your `appdata` folder for XBackBone. You
can do so by running:

```bash
sudo chown -R $USER:$USER ~/.config/appdata/xbackbone/
```

Restart your container by running:

```bash
docker restart xbackbone
```
