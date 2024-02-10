# qBittorrent

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/qbittorrent?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/qbittorrent)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-qbittorrent?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-qbittorrent)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/qbittorrent)

## Description

[qBittorrent](https://www.qbittorrent.org/) project aims to provide an
open-source software alternative to µTorrent. qBittorrent is based on the Qt
toolkit and libtorrent-rasterbar library.

## Install/Setup

This application does not have any specific setup instructions documented. If
you need assistance setting up this application please visit our
[support page](https://dockstarter.com/basics/support/).

## Accessing WebUI

qBittorrent randomly generates a password for the WebUI login at startup until
one has been set by the user. This means when you first setup the container you
wont be able to access WebUI until you find out the randomly generated password
The simplest way to see this password is to read the output of the startup 
message. To do this, you will need two shells, suchas two SSH sessions or if you
are accessing the machine directly a multiplexer such as ``tmux`` would work.

In the first shell, run ``sudo docker attach qbittorrent``. This is will print
any output of the container to this shell.

In the second shell, run ``sudo docker exec -it qbittorrent sh``. This will open
a shell inside the container, allowing you to run commands directly inside the
container. Run ``pgrep qbittorrent-nox`` which will print the process id for
qBittorrent running in the container and then ``kill <PID>`` where <PID> is the
number returned by ``pgrep``. Dont worry about having to restart qBittorrent,
as Docker will automatically restart the process as soon as you kill it. 

Now in the first shell you should see the startup output printed out. In that
output will be the username and password you can use to access WebUI. Once you
have successfully logged in you can set your own username and password in the
settings menu.

