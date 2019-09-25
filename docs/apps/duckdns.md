# DuckDNS

[DuckDNS](https://www.duckdns.org/) is a free service which will point a DNS (sub domains of duckdns.org) to an IP of your choice. The service is completely free, and doesn't require reactivation or forum posts to maintain its existence.

The GIT Repository for DuskDNS is located at [https://github.com/linuxserver/docker-duckdns](https://github.com/linuxserver/docker-duckdns)

## DuckDNS Install

When installing the DuckDNS container, the you will be prompted for your subdomain and token as part of the variables setup. To get that token, you need to go to the [duckdns website](https://www.duckdns.org/), register your subdomain(s) and retrieve your token. When the container creates and updates with your subdomain and token, it will then update your IP with the DuckDNS service every 5 minutes.
