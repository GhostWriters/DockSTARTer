# PiHole

[![Docker Pulls](https://img.shields.io/docker/pulls/pihole/pihole?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/pihole/pihole)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-duplicati?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-duplicati)

## Description

[Pi-hole](https://pi-hole.net/) is a DNS server that is used to filter out advertisements and other unwanted content on a network-wide level.

### Pi-hole Server IP Setup

By default, Pi-hole is configured to bind to `0.0.0.0` on port 53. This configuration should work out of the box for many people, however, if you encounter issues with this, you may need to disable or reconfigure any conflicting services running on port 53, such as `systemd-resolved` or set the `PIHOLE_SERVER_IP` variable to your server's IP address (e.g. 192.168.1.5). To stop systemd-resolved from listening on port 53, you can set `DNSStubListener=no` in `/etc/systemd/resolved.conf`.
