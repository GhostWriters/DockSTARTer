# DuckDNS

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/duckdns?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/duckdns)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-duckdns?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-duckdns)

## Description

[DuckDNS](https://www.duckdns.org/) is a free service which will point a DNS (sub domains of duckdns.org) to an IP of your choice. The service is completely free, and doesn't require reactivation or forum posts to maintain its existence.

### DuckDNS Install

When installing the DuckDNS container, the you will be prompted for your subdomain and token as part of the variables setup. To get that token, you need to go to the [DuckDNS website](https://www.duckdns.org/), register your subdomain(s) and retrieve your token. When the container creates and updates with your subdomain and token, it will then update your IP with the DuckDNS service every 5 minutes.
