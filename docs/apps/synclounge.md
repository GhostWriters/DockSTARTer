# SyncLounge

[SyncLounge](https://synclounge.tv/) sets up client and server applications to allow you to enjoy Plex with your friends, synchronizing the playback between players.

The GIT Repository for SyncLounge is located at [https://github.com/samcm/synclounge](https://github.com/samcm/synclounge).

## General Setup

SyncLounge works best if you have a domain to use and due to some issues (see **Issues** section below) it is recommended that you use this with the [Let's Encrypt](https://dockstarter.com/apps/letsencrypt/) container supported by DockSTARTer.

The below steps assume that you already have the [Let's Encrypt](https://dockstarter.com/apps/letsencrypt/) container selected, configured, and running. If not, do that first or along with steps 1 & 2 below.

1. Select SyncLounge from the DockSTARTer menu
    Note: If this is your first time running and configuring SyncLounge, keep the default settings. If you want to change these, see the **Issues** and **Advanced** sections below.
2. Complete the DockSTARTer configuration and run Docker Compose.
    Note: If you change either `web_root` and `server_root`, **DO NOT** include the leading `/`. This is handled for you.
3. Find the file called `synclounge.subdomain.conf.sample` in your [Let's Encrypt](https://dockstarter.com/apps/letsencrypt/) `proxy-confs` folder and rename it to `synclounge.subdomain.conf`.
4. Restart the letsencrypt container
   `docker restart letsencrypt`

You should now be able to go to `synclouge.yourdomain.com` and use SyncLounge!

## Issues

These are some issue found when setting this up.

1. The application doesn't properly respect `web_root` and `server_root` settings for some paths. These are noted in the sample nginx config.
2. Auto Join has a bug that causes it to not work most of the time.
3. Some of the settings are a bit finicky. For instance, `server_root` doesn't currently like to be set to `/`. If it is empty, it will get set to default `/slserver`.

## Advanced

Read **Issues** above first.

When changing any of the settings on the container, you need to make sure to change the respective values in the nginx configuratiion above. Example: You change `web_root` to `web` the you will need to change `location / {` in the configuration to `location /web {`.
