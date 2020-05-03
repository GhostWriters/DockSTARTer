# SyncLounge

[SyncLounge](https://synclounge.tv/) sets up client and server applications to allow you to enjoy Plex with your friends, synchronizing the playback between players.

The GIT Repository for SyncLounge is located at [https://github.com/samcm/synclounge](https://github.com/samcm/synclounge).

The GIT Repository for the LSIO SyncLounge container is located at [https://github.com/linuxserver/docker-synclounge](https://github.com/linuxserver/docker-synclounge).

## General Setup

SyncLounge works best if you have a domain to use and it is recommended that you use this with the [Let's Encrypt](https://dockstarter.com/apps/letsencrypt/) container supported by DockSTARTer. Also, since some Plex clients can only operate over HTTP, SyncLounge needs to be accessible by HTTP or your users will need to enable mixed content in their browser for ONLY the domain SyncLounge is on.

The below steps assume that you already have the [Let's Encrypt](https://dockstarter.com/apps/letsencrypt/) container selected, configured, and running. If not, do that first or along with steps 1 & 2 below.

1. Select SyncLounge from the DockSTARTer menu
1. Complete the DockSTARTer configuration.

    Make sure to set the SYNCLOUNGE_EXTERNAL_URL setting to the appropriate domain. E.g. - `synclouge.yourdomain.tld`  
    Otherwise, keep the default settings until you make sure everything is working okay

1. Run Docker Compose.
1. Find the file called `synclounge.subdomain.conf.sample` in your [Let's Encrypt](https://dockstarter.com/apps/letsencrypt/) `proxy-confs` folder and rename it to `synclounge.subdomain.conf`.

    By default, this has HTTP and HTTPS enabled.

1. Restart the letsencrypt container: `docker restart letsencrypt`

You should now be able to go to `synclouge.yourdomain.tld` and use SyncLounge!

Once you verify that everything is working, you can then start tinkering with settings.

If you would rather have SyncLounge running under a different domain as a subfolder, you can use the `synclounge.subfolder.conf.sample`. This file contains instructions for how to enable HTTP for the domain, how to force HTTP (if desired), as well as how to change the URL SyncLounge operates on.

## Advanced

### Override Servers List

If you want to override the Servers List you'll need to create an [Override](https://dockstarter.com/advanced/overrides/) to mount your servers file.

1. Create a file called `servers.json` in your SyncLounge folder (`~/.config/appdata/synclounge/`) and [populate it with servers](http://docs.synclounge.tv/self-hosted/settings/#customize-the-entire-list).

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
