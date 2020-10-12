# TransmissionVPN

[![Docker Pulls](https://img.shields.io/docker/pulls/haugene/transmission-openvpn?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/haugene/transmission-openvpn)
[![GitHub Stars](https://img.shields.io/github/stars/haugene/docker-transmission-openvpn?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/haugene/docker-transmission-openvpn)

## Description

This container contains [OpenVPN](https://openvpn.net/) and [Transmission](https://www.transmissionbt.com/) with a configuration where Transmission is running only when OpenVPN has an active tunnel. It bundles configuration files for many popular VPN providers to make the setup easier.

## Install/Setup

### TransmissionVPN WebUI Access

If you're attempting to get access to the TransmissionVPN WebUI remotely outside of your home network, you are going to have to do this through a reverse proxy using [SWAG](https://dockstarter.com/apps/swag/). Full details and steps are outlined here [VPN Information](https://dockstarter.com/advanced/vpn-info/).
