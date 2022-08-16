# Technical Info

## How Does TrunkSTARTer Work

TrunkSTARTer works by generating the configuration that **[Compose](https://docs.docker.com/compose/)** uses. A linux "pro" might use Compose to do what TrunkSTARTer does themselves but it would still take a lot longer.
> Compose is a tool for defining and running multi-container Docker applications. To learn more about Compose refer to the following [documentation](https://docs.docker.com/compose/).

_Compose_ works by reading [YAML (*.yml)](https://en.wikipedia.org/wiki/YAML#Example) configuration files with the paths, ports and parameters each Container should run with.

## YML Files

* **DO NOT EDIT THESE FILES DIRECTLY.** _Overriding_ these settings is easy but you must create a new file first. See the [Overrides / Introduction](https://trunkstarter.com/overrides/introduction) page.

YML files are akin to XML files and below is an example:

```yaml
services:
  sonarr:
    image: containers_author/sonarr
    container_name:  sonarr
    restart: ${SONARR_RESTART}
    environment:
      - PGID=${PGID}
      - PUID=${PUID}
      - TZ=${TZ}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKERCONFDIR}/sonarr:/config
      - ${DOCKERSTORAGEDIR}:/storage

```

In the example above,

**image** is the Container that you're using but also the quasi URL Docker will attempt to pull it from.

**container_name** is the human readable name Docker will use to describe it.

## Volumes

During the Getting Started section, you set **volumes** for your configuration, download and media etc in the`GLOBAL` section.

The path to Trunk Recorder's config in the above example, broken up, is `${DOCKERCONFDIR}/trunk-recorder` then the deliminator `:` followed by `/config`

`${DOCKERCONFDIR}/trunk-recorder` is the path on your computer that Trunk Recorder will see when it looks in `/config`. In this way, all your Containers will have their own private folder in your global config mount.

The `${DOCKERSTORAGEDIR}` location is public to all apps that need it. That means Trunk Recorder will be writing and reading from the same `${DOCKERSTORAGEDIR}:/storage` mounts as all your other containers.

**Again**, do not edit the default YML files, instead, see the section on [Overrides / Introduction](https://trunkstarter.com/overrides/introduction). (Assuming you are reading this page from start to finish for the first time) there is a reason you haven't seen their location yet ;)

## Ports

The ports for access to (and from) your apps are manipulated in your `.env` settings. I use the Trunk Recorder example a lot but if you're not familiar, it's default port is `8989`.

`TRUNK_RECORDER_PORT_8989=6969`

If you were to edit the `.env` for sonarr to the above, and run the generator again, you would then access Sonarr at `http://app.address:6969/calendar` instead of the default port, 8989.

* **Do not change your apps internal ports unless you know what you are doing.** For instance, if you change Trunk Recorders's internal port to 4545, it will still listen on 8989 by default. So then, you won't be able to access the container.
