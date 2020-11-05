# Organizr

[![Docker Pulls](https://img.shields.io/docker/pulls/organizr/organizr?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/organizr/organizr)
[![GitHub Stars](https://img.shields.io/github/stars/Organizr/docker-organizr?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/Organizr/docker-organizr)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/organizr)

## Description

[Organizr](https://organizr.app) allows you to setup "Tabs" that will be loaded all in one webpage. You can then work on your server with ease. Want to give users access to some Tabs? No problem, just enable user support and have them make an account. Want guests to be able to visit too? Enable Guest support for those tabs.

## Install/Setup

### Reverse Proxy as homepage via SWAG

In order to reverse proxy the Organizr container as your homepage via [SWAG](https://dockstarter.com/apps/swag/) you will need to rename the subfolder proxy sample with the following command:

```bash
cp ~/.config/appdata/swag/nginx/proxy-confs/organizr.subfolder.conf.sample ~/.config/appdata/swag/nginx/proxy-confs/organizr.subfolder.conf
```

Then edit `~/.config/appdata/swag/nginx/site-confs/default` to comment out the `location / {` and `location ~ \.php$ {` blocks down to their ending `}`.

Example Before:

```nginx

    location / {
        try_files $uri $uri/ /index.html /index.php?$args =404;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
    }
```

Example After:

```nginx

    # location / {
    #     try_files $uri $uri/ /index.html /index.php?$args =404;
    # }

    # location ~ \.php$ {
    #     fastcgi_split_path_info ^(.+\.php)(/.+)$;
    #     fastcgi_pass 127.0.0.1:9000;
    #     fastcgi_index index.php;
    #     include /etc/nginx/fastcgi_params;
    # }
```

Lastly, restart the [SWAG](https://dockstarter.com/apps/swag/) container:

```bash
docker restart swag
```

#### Pre-modified default site-conf

This example is based on the default site config included in SWAG found [here](https://github.com/linuxserver/docker-swag/blob/master/root/defaults/default). It has been modified to remove a lot of example comments and allow Organizr to take the place of your home page and replace the "Welcome to our server" page. This example may not be up to date with the most recent changes from upstream.

```nginx
## Version 2020/05/23 - Changelog: https://github.com/linuxserver/docker-swag/commits/master/root/defaults/default

# redirect all traffic to https
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

# main server block
server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;

    root /config/www;
    index index.html index.htm index.php;

    server_name _;

    # enable subfolder method reverse proxy confs
    include /config/nginx/proxy-confs/*.subfolder.conf;

    # all ssl related config moved to ssl.conf
    include /config/nginx/ssl.conf;

    # enable for ldap auth
    #include /config/nginx/ldap.conf;

    # enable for Authelia
    #include /config/nginx/authelia-server.conf;

    # enable for geo blocking
    # See /config/nginx/geoip2.conf for more information.
    #if ($allowed_country = no) {
    #return 444;
    #}

    client_max_body_size 0;

    # location / {
    #     try_files $uri $uri/ /index.html /index.php?$args =404;
    # }

    # location ~ \.php$ {
    #     fastcgi_split_path_info ^(.+\.php)(/.+)$;
    #     fastcgi_pass 127.0.0.1:9000;
    #     fastcgi_index index.php;
    #     include /etc/nginx/fastcgi_params;
    # }

}

# enable subdomain method reverse proxy confs
include /config/nginx/proxy-confs/*.subdomain.conf;
# enable proxy cache for auth
proxy_cache_path cache/ keys_zone=auth_cache:10m;

```
