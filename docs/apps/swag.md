# SWAG

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/swag?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/swag)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-swag?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-swag)

## Description

SWAG (Secure Web-server And Gateway) sets up an NGINX webserver and reverse proxy with PHP support and a built-in swag client that automates free SSL server certificate generation and renewal processes. It also contains fail2ban for intrusion prevention.

### LinuxServer's SWAG Starter Guide

[Official Guide](https://docs.linuxserver.io/general/swag)

If this is your first time learning about NGINX, proxies, or and Let's Encrypt, we highly recommend you read over the official guide for the container.

#### General Setup

Out of the box, the SWAG container created by [linuxserver.io](https://www.linuxserver.io/) performs reverse proxy functions using [NGINX](https://www.nginx.com/) and automatic https encrypted connections using certificates provided by [Let's Encrypt](https://letsencrypt.org/).

To configure your reverse proxy, consider if you want to use subfolders (ie. domain.com/portainer) or subdomains (ie. portainer.domain.com). Subdomains will take more configuration, as DNS entries and certificate subject alternate names are required.

The first thing to setup is your domain and email settings in `.docker/compose/.env` under `SWAG`. Set the `SWAG_EMAIL` and `SWAG_URL`. If using subdomains ensure to add each subdomain to `SWAG_SUBDOMAINS` as each subdomain prefix (e.g. `SWAG_SUBDOMAINS=portainer,deluge,pihole`.

There are a number of sample proxy configuration files found in `~/.config/appdata/swag/nginx/proxy-confs/` and in most cases will just need the .sample removed from the filename. Currently not every applicable app has an example configuration and are still being tested.

Subfolder Example:

```bash
cp ~/.config/appdata/swag/nginx/proxy-confs/portainer.subfolder.conf.sample ~/.config/appdata/swag/nginx/proxy-confs/portainer.subfolder.conf
```

This will make Portainer available at `domain.com/portainer`

Subdomain Example:

```bash
cp ~/.config/appdata/swag/nginx/proxy-confs/portainer.subdomain.conf.sample ~/.config/appdata/swag/nginx/proxy-confs/portainer.subdomain.conf
```

and will enable the service at `portainer.domain.com`

Each time you change a proxy conf file you will need to restart the Swag container:

```bash
docker restart swag
```

#### Redirect HTTP to HTTPS

This change will make it so that if you type <http://blahblah> it will redirect to <https://blahblah>

- Edit ~/.config/appdata/swag/nginx/site-confs/default

- Uncomment the relevant part of the file (see below)

```nginx
# listening on port 80 disabled by default, remove the "#" signs to enable
# redirect all traffic to https
server {
    listen 80;
    listen [::]:80;
    server_name _;
    return 301 https://$host$request_uri;
}
```

- Restart the swag container

```bash
docker restart swag
```

#### Ports in `proxy_pass`

By default, any ports listed inside any of the `.conf` files under `proxy_pass` will point to the internal port of the container. If the application you are trying to put behind the reverse proxy is hosted on another system, or on the host and it is using a different port, you can change the port. Remember to restart afterwards.
