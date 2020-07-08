# .env Variable Info

## COMPOSE_HTTP_TIMEOUT

* Default value: `60`

Description:
See [Compose HTTP Timeout](https://docs.docker.com/compose/reference/envvars/#compose_http_timeout)
This can be increased if you are seeing timeout issues when running compose. It is uncommon to need to adjust this option, but has been seen most commonly on very low powered CPU systems (older raspberry pi) or systems with failing storage (hard drives).

## DOCKERCONFDIR

* System Detected value: `~/.config/appdata`
* Default value: `~/.config/appdata`

Description:
This is the directory where all your containers' configuration is saved to.

## DOCKERGID

* System Detected value: The owner of the `docker` group on your system
* Default value: `999`

Description:
Default ID given to the `docker` group when it is created by [Docker](https://get.docker.com)

## DOCKERHOSTNAME

* System Detected value: The hostname of your system
* Default value: `DockSTARTer` (because we don't want it to be accidentally blank)

Description:
All containers will default to having this hostname.

## DOCKERLOGGING_MAXFILE

* Default value: `10`

Description:
The maximum number of log files that can be present. If rolling the logs creates excess files, the oldest file is removed.

## DOCKERLOGGING_MAXSIZE

* Default value: `200k`

Description:
The maximum size of the log before it is rotated. Size is specified in kilobytes.

## DOCKERSHAREDDIR

* System Detected value: `~/.config/appdata/shared`
* Default value: `~/.config/appdata/shared`

Description:
This directory will be mounted under `/shared` inside every container across DS. There is no specific use for this directory, it can be used however you like.

## DOWNLOADSDIR

* System Detected value: `~/Downloads`
* Default value: `/mnt/downloads`

Description:
This directory will be mounted under `/downloads` inside any container that is used for downloading. Do **not** use this directory as permanent storage for your media. See below for `MEDIADIR` directories.

**NOTE: `DOWNLOADSDIR` also gets mounted to `/data` inside some containers because that is what [binhex](https://hub.docker.com/u/binhex/) containers use. They will not work as intended otherwise.**

## MEDIADIR_AUDIOBOOKS

* System Detected value: `~/Audioooks`
* Default value: `/mnt/medialibrary/audiobooks`

Description:
This directory will be mounted under `/audiobooks` inside any container that is used to access your audiobooks library. This directory is meant to store media permanently.

## MEDIADIR_BOOKS

* System Detected value: `~/Books`
* Default value: `/mnt/medialibrary/books`

Description:
This directory will be mounted under `/books` inside any container that is used to access your books library. This directory is meant to store media permanently.

## MEDIADIR_COMICS

* System Detected value: `~/Comics`
* Default value: `/mnt/medialibrary/comics`

Description:
This directory will be mounted under `/comics` inside any container that is used to access your comics library. This directory is meant to store media permanently.

## MEDIADIR_MOVIES

* System Detected value: `~/Movies`
* Default value: `/mnt/medialibrary/movies`

Description:
This directory will be mounted under `/movies` inside any container that is used to access your movie library. This directory is meant to store media permanently.

## MEDIADIR_MUSIC

* System Detected value: `~/Music`
* Default value: `/mnt/medialibrary/music`

Description:
This directory will be mounted under `/music` inside any container that is used to access your music library. This directory is meant to store media permanently.

## MEDIADIR_TV

* System Detected value: `~/TV`
* Default value: `/mnt/medialibrary/tv`

Description:
This directory will be mounted under `/tv` inside any container that is used to access your TV library. This directory is meant to store media permanently.

## PGID

* System Detected value: Detects the ID of your group
* Default value: `1000` because this is the most common default on supported OS

Description:
This value can be obtained by using `id $user`.

## PUID

* System Detected value: Detects the ID of your user
* Default value: `1000` because this is the most common default on supported OS

Description:
This value can be obtained by using `id $user`.

## TZ

* System Detected value: Uses the value found in `/etc/timezone`
* Default value: `America/Chicago` because that's @nemchik's timezone (CST)

Description:

## LAN_NETWORK

* System Detected value: Detects your local IP range.
* Default value: `192.168.x.x/24`

Description:
If this value is blank or contains `x` DockSTARTer will automatically replace it with the System Detected value. Only accepts values in these ranges 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16.

## NS1

* Default value: `1.1.1.1`

Description:

## NS2

* Default value: `8.8.8.8`

Description:

## VPN_ENABLE

* Default value: `yes`

Description:
Only accepts `yes` or `no`. It specifies whether the VPN is enabled or not to be used by VPN enabled containers.

## VPN_OPTIONS

* Default value: Empty

Description:

## VPN_OVPNDIR

* Default value: `~/.config/appdata/.openvpn`

Description:
This directory will be used to store `ovpn` configurations that will be used by containers that are VPN enabled.

## VPN_PASS

* Default value: Empty

Description:
This is the password you use to login to your VPN provider.

## VPN_PROV

* Default value: `custom`

Description:

## VPN_USER

* Default value: Empty

Description:
This is the username you use to login with to your VPN provider.
