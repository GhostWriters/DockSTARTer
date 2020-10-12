# UniFi Controller

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/unifi-controller?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/unifi-controller)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-unifi-controller?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-unifi-controller)

## Description

[UniFi Controller](https://www.ubnt.com/enterprise/#unifi) software is a powerful, enterprise wireless software engine ideal for high-density client deployments requiring low latency and high uptime performance.

## Install/Setup

### Devices Get Stuck In "Adopting" State

When you first log in to your controller, you need to change the controller's IP address under `Settings > Controller Settings > Advanced Configuration`. On the right hand side, you will see `Controller Hostname/IP`, change this to your Docker host's IP address or hostname.

If you don't see this option or are having problems finding the settings then look over near the top and click `Can't find what you need? Switch to Classic Mode`. You will then need to go to `Controller` near the bottom and on the right hand side look for `Controller Hostname/IP` and change it to your Docker host IP address or hostname.
