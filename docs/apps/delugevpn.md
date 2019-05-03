
---
layout: default
---

If you're attempting to get access to the DelugeVPN WebUI remotely outside of your home network using LetsEncrypt, you will need to modify the LetsEncrypt configuration file to support the name difference. The sample configs are controlled by LSIO, not by DockSTARTer. So this change is required to get DelugeVPN WebUI running remotely.


The sample proxy configuration files found in `~/.config/appdata/letsencrypt/nginx/proxy-confs/` will need to be modified and as usual, have the .sample removed from the filename.

In addition you will need to edit the file ( `sudo nano deluge.subfolder.conf` or `sudo nano deluge.subdomain.conf` depending on your configuration desires) and change the below line:

Original
```
   set $upstream_deluge deluge;
```
Modified
```
   set $upstream_deluge delugevpn;
```

Save the file out and then restart your containers with a `ds -c` command.
