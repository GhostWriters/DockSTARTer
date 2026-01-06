# OpenVPNAS

## DEPRECATED

DEPRECATION NOTICE: This image is deprecated as of 2023-06-02. Use Gluetun or PrivoxyVPN.

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/openvpn-as?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/openvpn-as)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-openvpn-as?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-openvpn-as)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/.apps/openvpnas)

## Description

[OpenVPN-AS](https://openvpn.net/index.php/access-server/overview.html) is a full featured secure network tunneling VPN software solution that integrates OpenVPN server capabilities, enterprise management capabilities, simplified OpenVPN Connect UI, and OpenVPN Client software packages that accommodate Windows, MAC, Linux, Android, and iOS environments. OpenVPN Access Server supports a wide range of configurations, including secure and granular remote access to internal network and/ or private cloud network resources and applications with fine-grained access control.

## Install/Setup

The admin interface is available at `https://<ip>:943/admin` with a default user/password of admin/password

During first login, make sure that the "Authentication" in the Web GUI is set to `Local` instead of `PAM`. Then set up the user accounts with their password **(user accounts created under PAM do not survive container update or recreation)**.

The `admin` account is a system account (PAM) and after container update or recreation, its password reverts back to the default. It is highly recommended to block this user's access for security reasons. To restrict this account do the following:

- Set another user as an `admin`.
- Delete the `admin` user in the GUI.
- Modify the `as.conf` on your host located under `~/.config/appdata/openvpnas/config/etc` and replace the line boot_pam_users.0=admin with #boot_pam_users.0=admin (this only has to be done once and will survive container recreation).

### Server Network Settings

Make sure to change Hostname or IP Address to your public IP or public DNS name. It defaults to the docker internal IP. Also, this goes without saying, make sure to forward the correct ports on your firewall to your host IP.
