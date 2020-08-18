# rTorrentVPN

[![Docker Pulls](https://img.shields.io/docker/pulls/binhex/arch-rtorrentvpn?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/binhex/arch-rtorrentvpn)
[![GitHub Stars](https://img.shields.io/github/stars/binhex/arch-rtorrentvpn?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/binhex/arch-rtorrentvpn)

## Description

rTorrentVPN is a Docker build script for Arch Linux base with [rtorrent-ps](https://github.com/pyroscope/rtorrent-ps), [ruTorrent](https://github.com/Novik/ruTorrent), [autodl-irssi](https://github.com/autodl-community/autodl-irssi), [Privoxy](http://www.privoxy.org/) and [OpenVPN](https://openvpn.net/) all included in one image.

The support forum for rTorrentVPN is located [here](https://forums.unraid.net/topic/46127-support-binhex-rtorrentvpn/).

### rTorrentVPN WebUI Access

If you're attempting to get access to the rTorrentVPN WebUI remotely outside of your home network, you are going to have to do this through a reverse proxy using SWAG. Full details and steps are outlined here [VPN Information](https://dockstarter.com/advanced/vpn-info/).

The sample proxy configuration files found in `.config/appdata/swag/nginx/proxy-confs/` will need to be modified and as usual, have the .sample removed from the filename.

You will need to edit the appropriate proxy `.conf`. Enter either `sudo nano rutorrent.subfolder.conf` or `sudo nano rutorrent.subdomain.conf` depending on your configuration desires and change the below lines. NOTE: There will be multiple lines that need to be changed.

Original

```nginx
   set $upstream_rutorrent rutorrent;
   proxy_pass http://$upstream_rutorrent:80;
```

Modified

```nginx
   set $upstream_rutorrent rtorrentvpn;
   proxy_pass http://$upstream_rutorrent:9080;
```

Save the file and restart your container by running:

```bash
docker restart swag
```
