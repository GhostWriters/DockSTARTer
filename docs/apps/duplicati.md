# Duplicati

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/duplicati?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/duplicati)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-duplicati?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-duplicati)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/compose/.apps/duplicati)

## Description

[Duplicati](https://www.duplicati.com/) is a backup software solution to store encrypted backups online and works with standard protocols like FTP, SSH, WebDAV as well as popular services like Microsoft OneDrive, Amazon Cloud Drive & S3, Google Drive, box, Mega, hubiC and many others.

## Install/Setup

If you install Duplicati, you may be wondering what the important folders and files are to backup in case something goes wrong and you want to restore and be back up and running within minutes. Everything regarding DockSTARTer is found in /source like below: (You can exclude `.git` and `.github`)

![Source Configuration List](https://i.imgur.com/V2pyzW5.png)
