# Let's Encrypt

[Let's Encrypt](https://letsencrypt.org/) sets up an Nginx webserver and reverse proxy with php support and a built-in letsencrypt client that automates free SSL server certificate generation and renewal processes. It also contains fail2ban for intrusion prevention.

The GIT Repository for Let's Encrypt is located at [https://github.com/linuxserver/docker-letsencrypt](https://github.com/linuxserver/docker-letsencrypt).

## LinuxServer's NGINX/Let's Encrypt Starter Guide

If this is your first time learning about NGINX and Let's Encrypt, we highly recommend you read over their official guide, which can be found [here](https://blog.linuxserver.io/2019/04/25/letsencrypt-nginx-starter-guide/)

## General Setup

Out of the box, the Let's Encrypt container created by [linuxserver.io](https://www.linuxserver.io/) performs reverse proxy functions using [NGINX](https://www.nginx.com/) and automatic https encrypted connections using certificates provided by [LetsEncrypt](https://letsencrypt.org/). More on this container can be found [here](https://hub.docker.com/r/linuxserver/letsencrypt/).

To configure your reverse proxy, consider if you want to use subfolders (ie. domain.com/portainer) or subdomains (ie. portainer.domain.com). Subdomains will take more configuration, as DNS entries and certificate subject alternate names are required.

The first thing to setup is your domain and email settings in `.docker/compose/.env` under LETSENCRYPT. Set the `LETSENCRYPT_EMAIL` and `LETSENCRYPT_URL`. If using subdomains ensure to add each subdomain to `LETSENCRYPT_SUBDOMAINS` as each subdomain prefix (ie. `LETSENCRYPT_SUBDOMAINS=portainer,deluge,pihole`.

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

`docker restart letsencrypt`

## Part 2

If you haven't forwarded ports for LE before container was setup, stop container, delete letsencrypt config folder, run `ds -c`, and you should be good to go.

If you are **not** using subdomains:

1. Blank out LETSENCRYPT_SUBDOMAINS in ~/.docker/compose/.env Like so:

```nginx
LETSENCRYPT_SUBDOMAINS=
```

1. Fill in EMAIL, URL, like so:

```env
LETSENCRYPT_EMAIL=user@domain.com
LETSENCRYPT_URL=appropriateaddress.com
```

1. `cp organizr.subfolder.conf.sample organizr.subfolder.conf` in ~/.config/appdata/letsencrypt/nginx/proxy-confs
1. Edit ~/.config/appdata/letsencrypt/nginx/site-confs/default and comment out the following (As shown):

```nginx
#       location / {
#               try_files $uri $uri/ /index.html /index.php?$args =404;
#       }
```

## Ports In proxy_pass

Generally speaking, your configuration _does_ point to the port you specify, which is correct. DockSTARTer sets your app to 8080 on your internal network, but docker has a docker network as well. On _that_ network your app runs on the default port for the app! That is how containers like LetsEncrypt and Organizr (For example) communicate.

## Redirect HTTP to HTTPS

This change will make it so that if you type <http://blahblah> it will redirect to <https://blahblah>

1. Edit ~/.config/appdata/nginx/site-confs/default

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

`docker restart letsencrypt`
