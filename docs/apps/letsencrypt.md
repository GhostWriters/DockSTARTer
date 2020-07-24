# Let's Encrypt

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/letsencrypt?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/letsencrypt)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-letsencrypt?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-letsencrypt)

## Description

[Let's Encrypt](https://letsencrypt.org/) sets up an NGINX webserver and reverse proxy with PHP support and a built-in letsencrypt client that automates free SSL server certificate generation and renewal processes. It also contains fail2ban for intrusion prevention.

### LinuxServer's NGINX/Let's Encrypt Starter Guide

If this is your first time learning about NGINX and Let's Encrypt, we highly recommend you read over their official guide, which can be found [here](https://blog.linuxserver.io/2019/04/25/letsencrypt-nginx-starter-guide/)

#### General Setup

Out of the box, the Let's Encrypt container created by [linuxserver.io](https://www.linuxserver.io/) performs reverse proxy functions using [NGINX](https://www.nginx.com/) and automatic https encrypted connections using certificates provided by [LetsEncrypt](https://letsencrypt.org/).

To configure your reverse proxy, consider if you want to use subfolders (ie. domain.com/portainer) or subdomains (ie. portainer.domain.com). Subdomains will take more configuration, as DNS entries and certificate subject alternate names are required.

The first thing to setup is your domain and email settings in `.docker/compose/.env` under `LETSENCRYPT`. Set the `LETSENCRYPT_EMAIL` and `LETSENCRYPT_URL`. If using subdomains ensure to add each subdomain to `LETSENCRYPT_SUBDOMAINS` as each subdomain prefix (e.g. `LETSENCRYPT_SUBDOMAINS=portainer,deluge,pihole`.

There are a number of sample proxy configuration files found in `~/.config/appdata/letsencrypt/nginx/proxy-confs/` and in most cases will just need the .sample removed from the filename. Currently not every applicable app has an example configuration and are still being tested.

Subfolder Example:

```bash
cp ~/.config/appdata/letsencrypt/nginx/proxy-confs/portainer.subfolder.conf.sample ~/.config/appdata/letsencrypt/nginx/proxy-confs/portainer.subfolder.conf
```

This will make Portainer available at `domain.com/portainer`

Subdomain Example:

```bash
cp ~/.config/appdata/letsencrypt/nginx/proxy-confs/portainer.subdomain.conf.sample ~/.config/appdata/letsencrypt/nginx/proxy-confs/portainer.subdomain.conf
```

and will enable the service at `portainer.domain.com`

Each time you change a proxy conf file you will need to restart the LetsEncrypt container:

```bash
docker restart letsencrypt
```

#### Redirect HTTP to HTTPS

This change will make it so that if you type <http://blahblah> it will redirect to <https://blahblah>

1. Edit ~/.config/appdata/letsencrypt/nginx/site-confs/default

1. Uncomment the relevant part of the file (see below)

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

1. Restart the letsencrypt container

```bash
docker restart letsencrypt
```

#### Ports in `proxy_pass`

By default, any ports listed inside any of the `.conf` files under `proxy_pass` will point to the internal port of the container. If the application you are trying to put behind the reverse proxy is hosted on another system, or on the host and it is using a different port, you can change the port. Remember to restart afterwards.
