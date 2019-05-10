---
layout: default
---

Pi-hole takes over the local DNS service and may conflict with existing DNS services on your server. Ubuntu 18.04 currently uses systemd-resolv to server DNS and needs to be configured to either give up port 53 or be disabled.

## Netplan setup

On Ubuntu 18.04 and newer you will have `netplan` controlling your network and should see https://netplan.io/ for examples on how to configure it. You need to set your nameserver to use your LAN's DNS or a public DNS such as `1.1.1.1` before proceeding with any instructions below.

## Resolvconf

On Ubuntu 18.04, resolveconf was removed as the default means to control DNS.  In addition to the settings mentioned regarding netplan, we recommend setting up resolvconf.

To install run `sudo apt install resolvconf`

Edit `/etc/resolvconf/resolv.conf.d/head` using sudo and enter `nameserver 1.1.1.1` on the first uncommented line.

Restart the service `sudo service resolvconf restart`

## Stop systemd-resolv from listening on port 53

Edit `/etc/systemd/resolved.conf` and set `DNSStubListener=no` (make sure it is not commented out with a `#` at the beginning of the line) and then run `sudo systemctl restart systemd-resolved`

If that does not work you can try the following:

## Stop and disable systemd-resolv (only if the above does not work)
```
sudo systemctl stop systemd-resolv.service
sudo systemctl disable systemd-resolv.service
```

## Name resolution for localhost

In most cases it might be required to set your localhost name in `/etc/hosts`
```
127.0.0.1    machinename.localhost    machinename
127.0.0.1    domain.com
```
