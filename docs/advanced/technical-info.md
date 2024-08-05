# Technical Info

## How Does DockSTARTer Work

DockSTARTer works by generating the configuration that **[Compose](https://docs.docker.com/compose/)** uses. A linux "pro" might use Compose to do what DockSTARTer does themselves but it would still take a lot longer.

> Compose is a tool for defining and running multi-container Docker applications. To learn more about Compose refer to the following [documentation](https://docs.docker.com/compose/).

_Compose_ works by reading [YAML (\*.yml)](https://en.wikipedia.org/wiki/YAML#Example) configuration files with the paths, ports and parameters each Container should run with.

## YML Files

- **DO NOT EDIT THESE FILES DIRECTLY.** _Overriding_ these settings is easy but you must create a new file first. See the [Overrides / Introduction](https://dockstarter.com/overrides/introduction) page.

YML files are akin to XML files and below is an example:

```yaml
services:
  sonarr:
    image: containers_author/sonarr:latest
    container_name: sonarr
    restart: ${SONARR_RESTART}
    environment:
      - PGID=${PGID}
      - PUID=${PUID}
      - TZ=${TZ}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKER_VOLUME_CONFIG}/sonarr:/config
      - ${DOCKER_VOLUME_STORAGE}:/storage
```

In the example above,

**image** is the Container that you're using but also the quasi URL Docker will attempt to pull it from.

**container_name** is the human readable name Docker will use to describe it.

## Volumes

During the Getting Started section, you set **volumes** for your configuration, download and media etc in the`GLOBAL` section.

The path to Sonarr's config in the above example, broken up, is `${DOCKER_VOLUME_CONFIG}/sonarr` then the deliminator `:` followed by `/config`

`${DOCKER_VOLUME_CONFIG}/sonarr` is the path on your computer that Sonarr will see when it looks in `/config`. In this way, all your Containers will have their own private folder in your global config mount.

The `${DOCKER_VOLUME_STORAGE}` location is public to all apps that need it. That means Sonarr will be writing and reading from the same `${DOCKER_VOLUME_STORAGE}:/storage` mounts as Radarr, SickBeard etc AND your download clients.

**Again**, do not edit the default YML files, instead, see the section on [Overrides / Introduction](https://dockstarter.com/overrides/introduction). (Assuming you are reading this page from start to finish for the first time) there is a reason you haven't seen their location yet ;)

## Ports

The ports for access to (and from) your apps are manipulated in your `.env` settings. I use the Sonarr example a lot but if you're not familiar, it's default port is `8989`.

`SONARR_PORT_8989=6969`

If you were to edit the `.env` for sonarr to the above, and run the generator again, you would then access Sonarr at `http://app.address:6969/calendar` instead of the default port, 8989.

- **Do not change your apps internal ports unless you know what you are doing.** For instance, if you change Sonarr's internal port to 4545, it will still listen on 8989 by default. So then, you won't be able to access the WebGUI and without that, I don't even know where to begin changing the port in Sonarr's config files. And unless you want to run Transmission and RuTorrent side by side, I can't think of a good reason to change them in `.env` either.
