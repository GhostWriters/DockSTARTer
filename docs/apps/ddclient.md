# Ddclient

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/ddclient?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/ddclient)
[![GitHub Stars](https://img.shields.io/github/stars/ddclient/ddclient?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/ddclient/ddclient)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/ddclient)

## Description

[DDclient](https://sourceforge.net/p/ddclient/wiki/Home/) is a Perl client used to update dynamic DNS entries for accounts on a Dynamic DNS Network Service Provider. It was originally written by Paul Burry and is now mostly by wimpunk. It has the capability to update more than just dyndns and it can fetch your WAN-ipaddress in a few different ways.

## Install/Setup

Edit the included config to uncomment this line:

```ini
use=web, web=checkip.dyndns.org/, web-skip='IP Address' # found after IP Address
```

Then find your service of choice in the file and fill out the info as described. CloudFlare is recommended.
