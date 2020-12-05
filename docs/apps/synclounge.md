# SyncLounge

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/synclounge?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/synclounge)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-synclounge?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-synclounge)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/synclounge)

## Description

[SyncLounge](https://synclounge.tv/) is a third party tool that allows you to watch Plex in sync with your friends/family, wherever you are.

## Install/Setup

SyncLounge works best if you have a domain to use and it is recommended that you use this with the [SWAG](https://dockstarter.com/apps/swag/) container supported by DockSTARTer. Also, since some Plex clients can only operate over HTTP, SyncLounge needs to be accessible by HTTP or your users will need to enable mixed content in their browser for ONLY the domain SyncLounge is on.

The below steps assume that you already have the [SWAG](https://dockstarter.com/apps/swag/) container selected, configured, and running. If not, do that first or along with steps 1 & 2 below.

- Enable `SyncLounge` by running:

```bash
ds -a synclounge
```

- Complete the DockSTARTer configuration.

  - Make sure to set the `SYNCLOUNGE_EXTERNAL_URL` setting to the appropriate domain. E.g. - `synclouge.yourdomain.tld`
    Otherwise, keep the default settings until you make sure everything is working okay

- Recreate the container so settings get applied:

```bash
ds -c up synclounge
```

- Find the file called `synclounge.subdomain.conf.sample` in your [SWAG](https://dockstarter.com/apps/swag/) `proxy-confs` folder and rename it to `synclounge.subdomain.conf` (By default, this has HTTP and HTTPS enabled).

- Restart the [SWAG](https://dockstarter.com/apps/swag/) container:

```bash
docker restart swag
```

You should now be able to go to `synclouge.yourdomain.tld` and use SyncLounge!

Once you verify that everything is working, you can then start tinkering with settings.

If you would rather have SyncLounge running under a different domain as a subfolder, you can use the `synclounge.subfolder.conf.sample`. This file contains instructions for how to enable HTTP for the domain, how to force HTTP (if desired), as well as how to change the URL SyncLounge operates on.

### Advanced

#### Override Servers List

If you want to override the Servers List you'll need to create an [override](https://dockstarter.com/overrides/introduction) to mount your servers file.

- Create a file called `servers.json` in your SyncLounge folder (`~/.config/appdata/synclounge/`) and populate it with servers by following [this guide](http://docs.synclounge.tv/self-hosted/settings/#customize-the-entire-list).

  - Your servers.json file should NOT include the `"servers":` prefix (that is for the settings file which isn't used here). Only `[]` and the server objects inside should be included.

- Add or update your override file to include the example below:

  ```yaml
  version: "3.4"
  services:
    synclounge:
      volumes:
        - ${DOCKERCONFDIR}/synclounge/servers.json:/defaults/servers.json
  ```

- Recreate your container:

```bash
ds -c up synclounge
```
