# VPN Info

## VPN Services available to use through DockSTARTer

VPN use is only available where we have found a easily configured container that runs as its own self contained unit.

- DelugeVPN
- qBittorrentVPN
- rTorrentVPN
- SABnzbdVPN
- TransmissionVPN

## VPN tun driver

The VPN containers require an adjustment to your host system:

```bash
echo "iptable_mangle" | sudo tee /etc/modules-load.d/iptable_mangle.conf
echo "tun" | sudo tee /etc/modules-load.d/tun.conf
sudo reboot
```

## Access VPN containers remotely using LetsEncrypt

If you're attempting to access the Web UI for one of your VPN containers (e.g. TransmissionVPN, DelugeVPN, etc.) from outside of your home network using LetsEncrypt, you will need to modify the LetsEncrypt configuration file to support the name difference. The sample configs are controlled by [LSIO](https://www.linuxserver.io/), not by DockSTARTer. So this change is required to get the VPN containers running remotely.

The sample proxy configuration files found in `.docker/config/letsencrypt/nginx/proxy-confs/` will need to be modified and as usual, have the .sample removed from the filename.

You will also need to edit the appropriate proxy `.conf`. The below example uses the TransmissionVPN container as an example:

Enter either `sudo nano transmission.subfolder.conf` or `sudo nano transmission.subdomain.conf` depending on your configuration desires and change the below line:

Original

```nginx
   set $upstream_transmission transmission;
```

Modified

```nginx
   set $upstream_transmission transmissionvpn;
```

Save the file out and then restart your containers with a `ds -c` command.

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

## PIA with Transmission

For PIA VPN Configuration:
These pages come in handy -

- [https://github.com/haugene/docker-transmission-openvpn/blob/master/README.md#network-configuration-options](https://github.com/haugene/docker-transmission-openvpn/blob/master/README.md#network-configuration-options)

If you run into slow VPN issues, it may be the container is using a default .ovpn config. So you'd use something like this in a [Override](https://dockstarter.com/overrides): `OPENVPN_CONFIG=UK Southampton` depending on your region/location.
