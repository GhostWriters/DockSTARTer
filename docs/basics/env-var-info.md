# .env Variable Info

## COMPOSE_HTTP_TIMEOUT

- Default value: `60`

Description:
See [Compose HTTP Timeout](https://docs.docker.com/compose/reference/envvars/#compose_http_timeout)
This can be increased if you are seeing timeout issues when running compose. It is uncommon to need to adjust this option, but has been seen most commonly on very low powered CPU systems (older raspberry pi) or systems with failing storage (hard drives).

## DOCKER_GID

- System Detected value: The owner of the `docker` group on your system
- Default value: `999`

Description:
Default ID given to the `docker` group when it is created by [Docker](https://get.docker.com)

## DOCKER_HOSTNAME

- System Detected value: The hostname of your system
- Default value: `DockSTARTer` (because we don't want it to be accidentally blank)

Description:
All containers will default to having this hostname.

## DOCKER_VOLUME_CONFIG

- System Detected value: `~/.config/appdata`
- Default value: `~/.config/appdata`

Description:
This is the directory where all your containers' configuration is saved to.

## DOCKER_VOLUME_STORAGE

- System Detected value: `~/storage`
- Default value: `~/storage`

Description:
This directory will be mounted under `/storage` inside every container across DS. There is no specific use for this directory, it can be used however you like.

## PGID

- System Detected value: Detects the ID of your group
- Default value: `1000` because this is the most common default on supported OS

Description:
This value can be obtained by using `id -g $USER`.

## PUID

- System Detected value: Detects the ID of your user
- Default value: `1000` because this is the most common default on supported OS

Description:
This value can be obtained by using `id -u $USER`.

## TZ

- System Detected value: Uses the value found in `/etc/timezone`
- Default value: `America/Chicago` because that's @nemchik's timezone (CST)

Description:
System timezone, see [list of TZ Database Time Zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

## DEPRECATED VARS

### DOCKERLOGGING_MAXFILE

- Default value: `10`

Description:
The maximum number of log files that can be present. If rolling the logs creates excess files, the oldest file is removed.

### DOCKERLOGGING_MAXSIZE

- Default value: `200k`

Description:
The maximum size of the log before it is rotated. Size is specified in kilobytes.

### DOWNLOADSDIR

DEPRECATION NOTICE: This variable is now deprecated in favor of `DOCKER_VOLUME_STORAGE` which is mounted as a volume in all containers as `/storage`. This variable will be completely removed from all DockSTARTer app templates and no longer mounted as a volume at the end of 2020. The variable will not be removed from your `.env` file, however it will be sorted into the application specific variables at the bottom. If you require the volume you can continue using it via an [override](https://dockstarter.com/overrides/introduction).

- Default value: `/mnt/downloads`

Description:
This directory will be mounted under `/downloads` inside any container that is used for downloading. Do **not** use this directory as permanent storage for your media. See below for `MEDIADIR` directories.

**NOTE: `DOWNLOADSDIR` also gets mounted to `/data` inside some containers because that is what [binhex](https://hub.docker.com/u/binhex/) containers use. They will not work as intended otherwise.**

### MEDIADIR_AUDIOBOOKS

DEPRECATION NOTICE: This variable is now deprecated in favor of `DOCKER_VOLUME_STORAGE` which is mounted as a volume in all containers as `/storage`. This variable will be completely removed from all DockSTARTer app templates and no longer mounted as a volume at the end of 2020. The variable will not be removed from your `.env` file, however it will be sorted into the application specific variables at the bottom. If you require the volume you can continue using it via an [override](https://dockstarter.com/overrides/introduction).

- System Detected value: `~/Audioooks`
- Default value: `/mnt/medialibrary/audiobooks`

Description:
This directory will be mounted under `/audiobooks` inside any container that is used to access your audiobooks library. This directory is meant to store media permanently.

### MEDIADIR_BOOKS

DEPRECATION NOTICE: This variable is now deprecated in favor of `DOCKER_VOLUME_STORAGE` which is mounted as a volume in all containers as `/storage`. This variable will be completely removed from all DockSTARTer app templates and no longer mounted as a volume at the end of 2020. The variable will not be removed from your `.env` file, however it will be sorted into the application specific variables at the bottom. If you require the volume you can continue using it via an [override](https://dockstarter.com/overrides/introduction).

- System Detected value: `~/Books`
- Default value: `/mnt/medialibrary/books`

Description:
This directory will be mounted under `/books` inside any container that is used to access your books library. This directory is meant to store media permanently.

### MEDIADIR_COMICS

DEPRECATION NOTICE: This variable is now deprecated in favor of `DOCKER_VOLUME_STORAGE` which is mounted as a volume in all containers as `/storage`. This variable will be completely removed from all DockSTARTer app templates and no longer mounted as a volume at the end of 2020. The variable will not be removed from your `.env` file, however it will be sorted into the application specific variables at the bottom. If you require the volume you can continue using it via an [override](https://dockstarter.com/overrides/introduction).

- System Detected value: `~/Comics`
- Default value: `/mnt/medialibrary/comics`

Description:
This directory will be mounted under `/comics` inside any container that is used to access your comics library. This directory is meant to store media permanently.

### MEDIADIR_MOVIES

DEPRECATION NOTICE: This variable is now deprecated in favor of `DOCKER_VOLUME_STORAGE` which is mounted as a volume in all containers as `/storage`. This variable will be completely removed from all DockSTARTer app templates and no longer mounted as a volume at the end of 2020. The variable will not be removed from your `.env` file, however it will be sorted into the application specific variables at the bottom. If you require the volume you can continue using it via an [override](https://dockstarter.com/overrides/introduction).

- System Detected value: `~/Movies`
- Default value: `/mnt/medialibrary/movies`

Description:
This directory will be mounted under `/movies` inside any container that is used to access your movie library. This directory is meant to store media permanently.

### MEDIADIR_MUSIC

DEPRECATION NOTICE: This variable is now deprecated in favor of `DOCKER_VOLUME_STORAGE` which is mounted as a volume in all containers as `/storage`. This variable will be completely removed from all DockSTARTer app templates and no longer mounted as a volume at the end of 2020. The variable will not be removed from your `.env` file, however it will be sorted into the application specific variables at the bottom. If you require the volume you can continue using it via an [override](https://dockstarter.com/overrides/introduction).

- System Detected value: `~/Music`
- Default value: `/mnt/medialibrary/music`

Description:
This directory will be mounted under `/music` inside any container that is used to access your music library. This directory is meant to store media permanently.

### MEDIADIR_TV

DEPRECATION NOTICE: This variable is now deprecated in favor of `DOCKER_VOLUME_STORAGE` which is mounted as a volume in all containers as `/storage`. This variable will be completely removed from all DockSTARTer app templates and no longer mounted as a volume at the end of 2020. The variable will not be removed from your `.env` file, however it will be sorted into the application specific variables at the bottom. If you require the volume you can continue using it via an [override](https://dockstarter.com/overrides/introduction).

- System Detected value: `~/TV`
- Default value: `/mnt/medialibrary/tv`

Description:
This directory will be mounted under `/tv` inside any container that is used to access your TV library. This directory is meant to store media permanently.

### LAN_NETWORK

- System Detected value: Detects your local IP range.
- Default value: `192.168.x.x/24`

Description:
If this value is blank or contains `x` DockSTARTer will automatically replace it with the System Detected value. Only accepts values in these ranges 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16.

### NS1

- Default value: `1.1.1.1`

Description:

### NS2

- Default value: `8.8.8.8`

Description:

### VPN_CLIENT

- Default value: `openvpn`

Description:
Only accepts `openvpn` or `wireguard`.

### VPN_ENABLE

- Default value: `yes`

Description:
Only accepts `yes` or `no`. It specifies whether the VPN is enabled or not to be used by VPN enabled containers.

### VPN_OPTIONS

- Default value: Empty

Description:

### VPN_OVPNDIR

- Default value: `~/.config/appdata/.openvpn`

Description:
This directory will be used to store `ovpn` configurations that will be used by containers that are VPN enabled.

### VPN_PASS

- Default value: Empty

Description:
This is the password you use to login to your VPN provider.

### VPN_PROV

- Default value: `custom`

Description:

### VPN_USER

- Default value: Empty

Description:
This is the username you use to login with to your VPN provider.

### VPN_WGDIR

- Default value: `~/.config/appdata/.wireguard`

Description:
This directory will be used to store the `wg0.conf` file that will be used by containers that are VPN enabled.
