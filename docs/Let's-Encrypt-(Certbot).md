---
layout: default
---

## General Setup
Out of the box, the LetsEncrypt container provided performs both certificate renewals and reverse proxy functions. More on this container can be found [here](https://hub.docker.com/r/linuxserver/letsencrypt/).

To configure your reverse proxy, consider if you want to use subfolders (ie. domain.com/portainer) or subdomains (ie. portainer.domain.com). Subdomains will take more configuration, as DNS entries and certificate subject alternate names are required.

The first thing to setup is your domain and email settings in `.docker/compose/.env` under LETSENCRYPT. Set the `LETSENCRYPT_EMAIL` and `LETSENCRYPT_URL`. If using subdomains ensure to add each subdomain to `LETSENCRYPT_SUBDOMAINS` as each subdomain prefix (ie. `LETSENCRYPT_SUBDOMAINS=portainer,deluge,pihole`.

There are a number of sample proxy configuration files found in `.docker/config/letsencrypt/nginx/proxy-confs/` and in most cases will just need the .sample removed from the filename. Currently not every applicable app has an example configuration and are still being tested.

Subfolder Example:
```
cp ~/.docker/config/letsencrypt/nginx/proxy-confs/portainer.subfolder.conf.sample ~/.docker/config/letsencrypt/nginx/proxy-confs/portainer.subfolder.conf
```
This will make Portainer available at `domain.com/portainer`

Subdomain Example:
```
cp ~/.docker/config/letsencrypt/nginx/proxy-confs/portainer.subdomain.conf.sample ~/.docker/config/letsencrypt/nginx/proxy-confs/portainer.subdomain.conf
```
and will enable the service at `portainer.domain.com`

Each time you change a proxy conf file you will need to restart the LetsEncrypt container:

`docker restart letsencrypt`

## Part 2
If you haven't forwarded ports for LE before container was setup, stop container, delete letsencrypt config folder, run `ds -c`, and you should be good to go.

If you are **not** using subdomains:
1. Blank out LETSENCRYPT_SUBDOMAINS in ~/.docker/compose/.env Like so:
```
LETSENCRYPT_SUBDOMAINS=
```
2. Fill in EMAIL, URL, like so:
```
LETSENCRYPT_EMAIL=user@domain.com
LETSENCRYPT_URL=appropriateaddress.com
```
3. `cp organizr.subfolder.conf.sample organizr.subfolder.conf` in ~/.docker/config/letsencrypt/nginx/proxy-confs
4. Edit ~/.docker/config/letsencrypt/nginx/site-confs/default and comment out the following (As shown):
```
#       location / {
#               try_files $uri $uri/ /index.html /index.php?$args =404;
#       }
```

## Why does my LetsEncrypt proxy configuration for (insert app here) say one port, but I have to access it with another port?
Generally speaking, your configuration _does_ point to the port you specify, which is correct. DockSTARTer sets your app to 8080 on your internal network, but docker has a docker network as well. On _that_ network your app runs on the default port for the app! That is how containers like LetsEncrypt and Organizr (For example) communicate.

## How do i automatically make http calls redirect to https for letsencrypt?

This change will make it so that if you type http://blahblah it will redirect to https://blahblah

1. Edit /config/nginx/site-confs/default

2. Uncomment the relevant part of the file (see below)
```
# listening on port 80 disabled by default, remove the "#" signs to enable
# redirect all traffic to https
server {
	listen 80;
	listen [::]:80;
	server_name _;
	return 301 https://$host$request_uri;
}
```

3. Restart the letsencrypt container
`docker restart letsencrypt`

## How do i redirect the main index.html page to organizr?

If you want https://mydomain.duckdns.org to load organizr you can do the following.

1. Goto ~.docker/config/letsencrypt/www
2. Replace index.html with index.php
3. Edit index.php and replace it with the following single line
```
<?php header("Location: https://organizr.mydomain.duckdns.org"); ?>
```
4. Restart the letsencrypt container
`docker restart letsencrypt`
