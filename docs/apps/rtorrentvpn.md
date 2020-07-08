# rTorrentVPN

[rTorrentVPN](http://deluge-torrent.org/) is a Docker build script for Arch Linux base with [rTorrent-ps](https://github.com/pyroscope/rtorrent-ps), [ruTorrent](https://github.com/Novik/ruTorrent), [autodl-irssi](https://github.com/autodl-community/autodl-irssi), [OpenVPN](https://openvpn.net/) and [Privoxy](http://www.privoxy.org/) all included in one image.

The support forum for rTorrentVPN is located at [https://forums.unraid.net/topic/46127-support-binhex-rtorrentvpn/](https://forums.unraid.net/topic/46127-support-binhex-rtorrentvpn/).

The GIT Repository for rTorrentVPN is located at [https://github.com/binhex/arch-rtorrentvpn](https://github.com/binhex/arch-rtorrentvpn).

## rTorrentVPN WebUI Access

If you're attempting to get access to the rTorrentVPN WebUI remotely outside of your home network, you are going to have to do this through a Proxy using LetsEncrypt. Full details and steps are outlined here [VPN Information](https://dockstarter.com/advanced/vpn-info/).

The sample proxy configuration files found in `.docker/config/letsencrypt/nginx/proxy-confs/` will need to be modified and as usual, have the .sample removed from the filename.

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

Save the file out and then restart your containers with a `ds -c` command.
