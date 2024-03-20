# TransmissionVPN

## DEPRECATED

DEPRECATION NOTICE: This image is deprecated as of 2024-02-18. Use Transmission with Gluetun or PrivoxyVPN.

[![Docker Pulls](https://img.shields.io/docker/pulls/haugene/transmission-openvpn?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/haugene/transmission-openvpn)
[![GitHub Stars](https://img.shields.io/github/stars/haugene/docker-transmission-openvpn?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/haugene/docker-transmission-openvpn)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/transmissionvpn)

## Description

This container contains [OpenVPN](https://openvpn.net/) and
[Transmission](https://www.transmissionbt.com/) with a configuration where
Transmission is running only when OpenVPN has an active tunnel. It bundles
configuration files for many popular VPN providers to make the setup easier.

## Install/Setup

This application does not have any specific setup instructions documented. If
you need assistance setting up this application please visit our
[support page](https://dockstarter.com/basics/support/).

### TransmissionVPN WebUI Access

If you're attempting to get access to the TransmissionVPN WebUI remotely outside
of your home network, you are going to have to do this through a reverse proxy
using [SWAG](https://dockstarter.com/apps/swag/). Full details and steps are
outlined here [VPN Information](https://dockstarter.com/advanced/vpn-info/).
