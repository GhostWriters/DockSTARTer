---
layout: default
---

# Advanced Settings


* _Please note that much of the documentation below will not be necessary once the planned GUI is implemented._ Also, this guide is meant to be generic, I mention app names interchangeable below. Until the GUI, this is meant to teach you enough about how things work to make some changes where you need to.

### How Does DockSTARTer Work?

DockSTARTer works by generating the configuration that **[Compose](https://docs.docker.com/compose/)** uses. A linux "pro" might use Compose to do what DockSTARTer does themselves but it would still take a lot longer.
> Compose is a tool for defining and running multi-container Docker applications. To learn more about Compose refer to the following [documentation](https://docs.docker.com/compose/).

_Compose_ works by reading [YAML (*.yml)](https://en.wikipedia.org/wiki/YAML#Example) configuration files with the paths, ports and parameters each Container should run with.  

## YML Files
* **DO NOT EDIT THESE FILES DIRECTLY.** _Overriding_ these settings is easy but you must create a new file first. See the section, _Overrides_, below.

YML files are akin to XML files and below is an example:
```
version:             "3.6"
services:
  sonarr:
    image:           containers_author/sonarr
    container_name:  sonarr
    restart:         always
    environment:
      - PGID=${PGID}
      - PUID=${PUID}
      - TZ=${TZ}
    volumes:
      - ${DOCKERCONFDIR}/sonarr:/config
      - ${DOWNLOADSDIR}:/downloads
      - ${MEDIADIR_TV}:/tv
```

In the example above,

**image** is the Container that you're using but also the quasi URL Docker will attempt to pull it from.

**container_name** is the human readable name Docker will use to describe it.

### Volumes
During the Getting Started section, you set **volumes** for your configuration, download and media etc in the`GLOBAL` section.

The path to Sonarr's config in the above example, broken up, is `${DOCKERCONFDIR}/sonarr` then the deliminator `:` followed by `/config`

`${DOCKERCONFDIR}/sonarr` is the path on your computer that Sonarr will see when it looks in `/config`. In this way, all your Containers will have their own private folder in your global config mount.

The `${DOWNLOADSDIR}` location is public to all apps that need it. That means Sonarr will be writing and reading from the same `${DOWNLOADSDIR}:/downloads' mounts as Radarr, SickBeard etc AND your download clients. Here's mine!

```
p2p@p2pmachine:/mnt/p2pDownloads$ ls -la
total 13496
drwxr-xr-x 14 p2p  p2p      4096 Jun 25 19:08 .
drwxr-xr-x  6 root root     4096 Jun 23 16:20 ..
drwxr-xr-x  3 p2p  p2p      4096 Jun 24 08:26 complete
drwxr-xr-x  5 p2p  p2p      4096 Jun 30 08:31 completed
drwxr-xr-x  2 p2p  p2p      4096 Jun 24 08:26 incoming
drwxr-xr-x  4 p2p  p2p      4096 Jun 30 19:53 incomplete
drwxr-xr-x  4 p2p  p2p      4096 Jun 30 14:04 intermediate
drwxr-xr-x  2 p2p  p2p     16384 Jun 23 15:32 lost+found
drwxr-xr-x  2 p2p  p2p      4096 Jun 30 14:03 nzb
-rw-r--r--  1 p2p  p2p  13726266 Jun 30 20:10 nzbget.log
drwxr-xr-x  2 p2p  p2p     20480 Jun 30 14:04 queue
drwxr-xr-x  2 p2p  p2p      4096 Jun 30 14:03 tmp
drwxr-xr-x  7 p2p  p2p      4096 Jun 30 19:53 transmission
drwxr-xr-x  2 p2p  p2p      4096 Jun 23 16:43 watch
drwxr-xr-x  2 p2p  p2p      4096 Jun 24 08:26 watched
p2p@p2pmachine:/mnt/p2pDownloads$
```
The downside to this is that your root downloads location will start to look very messy if you have a lot of downloaders, with multiple complete and incomplete folders, some even being used by different download clients.

Ineligant as that is, and a lot of those folders _could_ be deleted, from unused testing etc, this is the default behavior because Sonarr and (for instance) Transmission need to refer to the same paths in order to seamlessly move files around. Sonarr and Radarr both support path mapping but having DS configure them is outside the scope of this project.

Instead, if you want to run multiple download containers, configure Transmissions download directories itself (at `ip.add.ress:9091/transmission/`).

Change them all to `/downloads/transmission/incomplete`,`/downloads/transmission/complete` etc etc. Then it has it's own folder but can still report the same root path.

**Again**, do not edit the default YML files, instead, see the section on _Overrides_, below. (Assuming you are reading this page from start to finish for the first time) there is a reason you haven't seen their location yet ;)
### Ports
The ports for access to (and from) your apps are manipulated in your `.env`ironment settings. I use the Sonarr example a lot but if you're not familiar, it's default port is `8989`.

`SONARR_PORT_8989=6969`

If you were to edit the `.env` for sonarr to the above, and run the generator again, you would then access Sonarr at `http://app.address:6969/calendar` instead of the default port, 8989.

 * **Do not change your apps internal ports unless you know what you are doing.** For instance, if you change Sonarr's internal port to 4545, it will still listen on 8989 by default. So then, you won't be able to access the WebGUI and without that, I don't even know where to begin changing the port in Sonarr's config files. And unless you want to run Transmission and RuTorrent side by side, I can't think of a good reason to change them in `.env` either.
