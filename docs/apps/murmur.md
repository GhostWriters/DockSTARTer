# Murmur

[![Docker Pulls](https://img.shields.io/docker/pulls/goofball222/murmur?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/goofball222/murmur)
[![GitHub Stars](https://img.shields.io/github/stars/goofball222/murmur?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/goofball222/murmur)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/murmur)

## Description

[Murmur](https://github.com/mumble-voip/mumble) is a VoIP server for Mumble. It
is an open-source application that is similar to programs such as Ventrilo or
TeamSpeak.

## Install/Setup

This application does not have any specific setup instructions documented. If
you need assistance setting up this application please visit our
[support page](https://dockstarter.com/basics/support/).

### SuperUser Password

The default user on a Murmur server is called 'SuperUser'. An initial password
is generated for this user on first run, and you can find it by looking at the
Docker logs for the Murmur container. It will be in a line that looks like
`Password for 'SuperUser' set to 'something'`. You can use this password to
login.

It is possible to set a specific SuperUser password by using the `MURMUR_SUPW`
environment variable in `env_files/murmer.env`, but due to a quirk with the way
Murmur is implemented, if you set this SuperUser password variable, the
container will simply update the SuperUser password and exit. As such, this
variable needs to be unset to start Murmur normally.
