# Calibre-Web

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/calibre-web?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/calibre-web)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-calibre-web?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-calibre-web)

## Description

[Calibre-web](https://github.com/janeczku/calibre-web) is a web app providing a clean interface for browsing, reading and downloading eBooks using an existing [Calibre](https://calibre-ebook.com/) database. It is also possible to integrate google drive and edit metadata and your calibre library through the app itself.

### Calibre-Web installation

The Calibre-Web docker is only a web front end to the actual Calibre application/database itself. You still need a Calibre  metadata.db file for Calibre Web to function. To get this, you have to install [Calibre](https://calibre-ebook.com/download) somewhere and you can move the metadata.db file into either your /books or /shared folder.
