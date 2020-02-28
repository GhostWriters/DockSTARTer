# SyncLounge

[SyncLounge](https://synclounge.tv/) sets up client and server applications to allow you to enjoy Plex with your friends, synchronizing the playback between players.

The GIT Repository for SyncLounge is located at [https://github.com/samcm/synclounge](https://github.com/samcm/synclounge).

## General Setup

SyncLounge requires that you have a domain to use and due to some issues (see **Issues** section below) . It is recommended that you use this with the [Let's Encrypt](https://dockstarter.com/apps/letsencrypt/) container supported by DockSTARTer.

The below steps assume that you already have the [Let's Encrypt](https://dockstarter.com/apps/letsencrypt/) container selected, configured, and running. If not, do that first.

1. Select SyncLounge from the DockSTARTer menu
    Note: If this is your first time running and configuring SyncLounge, keep the default settings. If you want to change these, see the **Issues** and **Advanced** sections below.
2. Copy and paste the following into a file called `synclounge.subdomain.conf` in your [Let's Encrypt](https://dockstarter.com/apps/letsencrypt/) `proxy-confs` folder.
    ```nginx
    server {
       listen 443 ssl;
       listen [::]:443 ssl;

       server_name synclounge.*;

       include /config/nginx/ssl.conf;

        client_max_body_size 0;
        proxy_redirect off;
        proxy_buffering off;

        ###
        # Client
        ###

        # Redirect root to SyncLounge's base url (web root)
        location = / {
            return 301 $scheme://$host/lounge;
        }

        # Proxy for the client
        location /lounge {
            include /config/nginx/proxy.conf;
            resolver 127.0.0.11 valid=30s;
            set $upstream_app synclounge;
            set $upstream_port 8088;
            set $upstream_proto http;

            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_pass $upstream_proto://$upstream_app:$upstream_port;
        }

        # Due to a bug in SyncLounge, some requests like /config don't respect the base url (web root) setting
        location / {
            include /config/nginx/proxy.conf;
            resolver 127.0.0.11 valid=30s;
            set $upstream_app synclounge;
            set $upstream_port 8088;
            set $upstream_proto http;

            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_pass $upstream_proto://$upstream_app:$upstream_port;
        }

        # Invite links need to be rewritten to use the base url (web root) setting
        location /invite/ {
            return 301 $scheme://$host/lounge$request_uri;
        }

        ###
        # Server
        ###

        # Proxy for the server
        location /server {
            include /config/nginx/proxy.conf;
            resolver 127.0.0.11 valid=30s;
            set $upstream_app synclounge;
            set $upstream_port 8089;
            set $upstream_proto http;

            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_pass $upstream_proto://$upstream_app:$upstream_port;
        }

        # Due to a bug in SyncLounge, some websockets calls don't respect the base url (server root) setting
        location /socket.io {
            resolver 127.0.0.11 valid=30s;
            set $upstream_app synclounge;
            set $upstream_port 8089;
            set $upstream_proto http;

            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_pass $upstream_proto://$upstream_app:$upstream_port/server/socket.io/;
        }

    }
    ```
1. Restart the letsencrypt container
   `docker restart letsencrypt`

You should now be able to go to `synclouge.yourdomain.com` and use SyncLounge!

## Issues

There are a number of issues found when setting this up.
1. The docker container doesn't properly respect `web_root` and `server_root` settings for some paths. These are noted in the sample nginx config above.
2. Auto Join has a bug that causes it to not work most of the time.
3. Some of the settings are a bit finicky. For instance, `web_root` and `server_root` don't like to be set to `/` and they if they are empty, they will get set to defaults `/slweb` and `/slserver`.

## Advanced

Read **Issues** above first.

If you change either `web_root` and `server_root`, **DO NOT** include the leading `/`. This is handled for you.

When changing any of the settings on the container, you need to make sure to change the respective values in the nginx configuratiion above. Example: You change `web_root` to `web` the you will need to change `lounge` in the configuration to `web`.