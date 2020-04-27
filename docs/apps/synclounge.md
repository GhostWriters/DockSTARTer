# SyncLounge

[SyncLounge](https://synclounge.tv/) sets up client and server applications to allow you to enjoy Plex with your friends, synchronizing the playback between players.

The GIT Repository for SyncLounge is located at [https://github.com/samcm/synclounge](https://github.com/samcm/synclounge).

The GIT Repository for the LSIO SyncLounge container is located at [https://github.com/linuxserver/docker-synclounge](https://github.com/linuxserver/docker-synclounge).

## General Setup

SyncLounge works best if you have a domain to use and it is recommended that you use this with the [Let's Encrypt](https://dockstarter.com/apps/letsencrypt/) container supported by DockSTARTer.

The below steps assume that you already have the [Let's Encrypt](https://dockstarter.com/apps/letsencrypt/) container selected, configured, and running. If not, do that first or along with steps 1 & 2 below.

1. Select SyncLounge from the DockSTARTer menu

    Note: If this is your first time running and configuring SyncLounge, keep the default settings to make sure everything works before making modifications

1. Complete the DockSTARTer configuration and run Docker Compose.
1. Find the file called `synclounge.subdomain.conf.sample` in your [Let's Encrypt](https://dockstarter.com/apps/letsencrypt/) `proxy-confs` folder and rename it to `synclounge.subdomain.conf`.
1. Restart the letsencrypt container
   `docker restart letsencrypt`

You should now be able to go to `synclouge.yourdomain.tld` and use SyncLounge!

## Advanced

### Override Servers List

If you want to override the Servers List you'll need to create an [Override](https://dockstarter.com/advanced/overrides/) to mount your servers file.

1. Create a file called `servers.json` in your SyncLounge folder and [populate it with servers](http://docs.synclounge.tv/self-hosted/settings/#customize-the-entire-list).

    Note: Your servers.json file should NOT include `"servers":` prefix (that is for the settings file which isn't used here). Only `[]` and the server objects inside should be included.

1. Add or update your overrides file to include the example below
1. Restart your SyncLounge container: `docker restart synclounge`

#### Example

```yaml
version: "3.4" # this must match the version in docker-compose.yml
services:
  synclounge:
    volumes:
        - ${DOCKERSHAREDDIR}/synclounge/servers.json:/defaults/servers.json
```
