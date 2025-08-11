# SWAG

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/swag?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/swag)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-swag?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-swag)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/compose/.apps/swag)

## Description

[SWAG (Secure Web-server And Gateway)](https://github.com/linuxserver/docker-swag)
sets up an NGINX webserver and reverse proxy with PHP support and a built-in
swag client that automates free SSL server certificate generation and renewal
processes. It also contains fail2ban for intrusion prevention.

## Install/Setup

[Official Guide](https://docs.linuxserver.io/general/swag)

If this is your first time learning about NGINX, proxies, or and Let's Encrypt,
we highly recommend you read over the official guide for the container.

### General Setup

Out of the box, the SWAG container created by
[linuxserver.io](https://www.linuxserver.io/) performs reverse proxy functions
using [NGINX](https://www.nginx.com/) and automatic https encrypted connections
using certificates provided by [Let's Encrypt](https://letsencrypt.org/).

To configure your reverse proxy, consider if you want to use subfolders (ie.
domain.com/portainer) or subdomains (ie. portainer.domain.com). Subdomains will
take more configuration, as DNS entries and certificate subject alternate names
are required.

The first thing to setup is your domain and email settings in
`.docker/compose/.env.app.swag`. Set the `EMAIL` and `URL`. If
using subdomains ensure to add each subdomain to `SUBDOMAINS` as each
subdomain prefix (e.g. `SUBDOMAINS=portainer,deluge,pihole`.

There are a number of sample proxy configuration files found in
`~/.config/appdata/swag/nginx/proxy-confs/` and in most cases will just need the
.sample removed from the filename. Currently not every applicable app has an
example configuration and are still being tested.

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

Each time you change a proxy conf file you will need to restart the Swag
container:

```bash
docker restart swag
```
