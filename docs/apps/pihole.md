# PiHole

[![Docker Pulls](https://img.shields.io/docker/pulls/pihole/pihole?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/pihole/pihole)
[![GitHub Stars](https://img.shields.io/github/stars/pi-hole/docker-pi-hole?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/pi-hole/docker-pi-hole)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/pihole)

## Description

[Pi-hole](https://pi-hole.net/) is a DNS server that is used to filter out advertisements and other unwanted content on a network-wide level.

## Install/Setup

By default, Pi-hole is configured to bind to `0.0.0.0` on port 53. While this configuration should work out of the box for many people, if you encounter issues with this, it is recommended that you set the `PIHOLE_SERVER_IP` variable to your server's IP address (e.g. 192.168.1.5). If you still encounter difficulties getting Pi-hole to work, you may need to disable or reconfigure any conflicting services running on port 53, such as `systemd-resolved`. Although this is a more advanced configuration, you can also configure systemd-resolved to not listen on port 53 by setting `DNSStubListener=no` in `/etc/systemd/resolved.conf`.

## Install/Setup
