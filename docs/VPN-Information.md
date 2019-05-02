---
layout: default
---

## What VPN Services are available to use through DockSTARTer?
At the moment VPN is only available where we have found a easily configured container that runs as its own self contained unit. TransmissionVPN, SabNzbDVPN, DelugeVPN & rTorrentVPN are currently available.

## VPN tun driver
The VPN containers require an adjustment to your host system:
```
echo "iptable_mangle" | sudo tee /etc/modules-load.d/iptable_mangle.conf
echo "tun" | sudo tee /etc/modules-load.d/tun.conf
sudo reboot
```

## How can I check if my VPN is working?

* https://torguard.net/checkmytorrentipaddress.php
* http://www.doileak.com/
* http://ipmagnet.services.cbcdn.com/
* http://test.torrentprivacy.com/

### What if I want to use a VPN for _everything_?
If you require VPN on all connections it is recommended to install OpenVPN as you normally would ( in /etc/openvpn etc etc) and then having the Docker service started and stopped by the up / down scripts.

You can disable auto starting of the containers by disabling the docker service. On Ubuntu, I used

`sudo systemctl disable docker`

My vpnup.sh consists of

```
#!/bin/bash
if [[ -L "/sbin/init" ]]; then
    systemctl start docker
else
    /etc/init.d/docker start
fi
```
and Down -
```
#!/bin/bash
if [[ -L "/sbin/init" ]]; then
    systemctl stop docker
else
    /etc/init.d/docker stop
fi
```


* If you make changes to the `.env`ironment file, you will need to run the generator again. If you stop the OpenVPN service, thereby stopping Docker, the generation might not work. Start your OpenVPN service and run the generation again if it didn't work.
```
cd ~/.docker/compose
sudo ds -c

```

## PIA with Transmission
For PIA VPN Configuration:
These pages come in handy -
* https://github.com/haugene/docker-transmission-openvpn/blob/master/README.md#network-configuration-options

If you run into slow VPN issues, it may be the container is using a default .ovpn config. So you'd use something like this in a [Override](https://github.com/GhostWriters/DockSTARTer/wiki/Overrides): `OPENVPN_CONFIG=UK Southampton` depending on your region/location.
