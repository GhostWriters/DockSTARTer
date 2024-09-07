# VPN Info

## VPN Services available to use through DockSTARTer

VPN use is only available where we have found a easily configured container that runs as its own self contained unit.

- Gluetun
- PrivoxyVPN

## VPN tun driver

The VPN containers require an adjustment to your host system:

```bash
echo "iptable_mangle" | sudo tee /etc/modules-load.d/iptable_mangle.conf
echo "tun" | sudo tee /etc/modules-load.d/tun.conf
sudo reboot
```

## How to check if the VPN is working

- [https://torguard.net/checkmytorrentipaddress.php](https://torguard.net/checkmytorrentipaddress.php)
- [http://www.doileak.com/](http://www.doileak.com/)
- [http://ipmagnet.services.cbcdn.com/](http://ipmagnet.services.cbcdn.com/)
- [http://test.torrentprivacy.com/](http://test.torrentprivacy.com/)

## Use a VPN for _everything_

If you require VPN on all connections it is recommended to install OpenVPN as you normally would ( in `/etc/openvpn` etc etc) and then have the Docker service started and stopped by the up / down scripts.

You can disable auto starting of the containers by disabling the docker service. An example provided by a user in our community for Ubuntu:

`sudo systemctl disable docker`

vpnup.sh

```bash
#!/bin/bash
if [[ -L "/sbin/init" ]]; then
    systemctl start docker
else
    /etc/init.d/docker start
fi
```

vpndown.sh

```bash
#!/bin/bash
if [[ -L "/sbin/init" ]]; then
    systemctl stop docker
else
    /etc/init.d/docker stop
fi
```

If you make changes to your `.env` file you will need to run `ds -c`. If you stop the OpenVPN service, thereby stopping Docker, DockSTARTER might fail. Start your OpenVPN service and run `ds -c` again if it didn't work.
