# `.env` Variable Info

## COMPOSE_HTTP_TIMEOUT
* Default value: `60`

Description:
See [Compose HTTP Timeout](https://docs.docker.com/compose/reference/envvars/#compose_http_timeout)
This can be increased if you are seeing timeout issues when running compose. It is uncommon to need to adjust this option, but has been seen most commonly on very low powered CPU systems (older raspberry pi) or systems with failing storage (hard drives).

## DOCKERCONFDIR
* System Detected value: `~/.config/appdata`

* Default value: `~/.config/appdata`

Description: This is the directory where all your docker configuration is saved to.

## DOCKERGID
* System Detected value: The owner of the `docker` group on your system

* Default value: `999`

Description: Default ID given to the `docker` group when it is created by [Docker](https://get.docker.com)

## DOCKERHOSTNAME
* System Detected value:

* Default value: `DockSTARTer` (because we don't want it to be accidentally blank)

Description: All containers will default to having this hostname.

## DOCKERLOGGING_MAXFILE
* Default value: `10`

Description:

## DOCKERLOGGING_MAXSIZE
* Default value: `200k`

Description: Maximum size in kilobytes that the log file will be before it is rotated.

## DOCKERSHAREDDIR
* System Detected value: `~/.config/appdata/shared`

* Default value: `~/.config/appdata/shared`

Description: This is the default shared folder between all containers. You can place anything here and it can be accessed from any other container, such as scripts.

## DOWNLOADSDIR
* System Detected value: `~/Downloads`

* Default value: `/mnt/downloads`

Description: This is the default folder where all your downloads are located. To be used with SABnzbd, NZBGet, and any torrent clients.

## MEDIADIR_AUDIOBOOKS
* System Detected value: `~/Audioooks`

* Default value: `/mnt/medialibrary/audiobooks`

Description: This is the default folder where all audiobooks are stored.

## MEDIADIR_BOOKS
* System Detected value: `~/Books`

* Default value: `/mnt/medialibrary/books`

Description: This is the default folder where all books are stored.

## MEDIADIR_COMICS
* System Detected value: `~/Comics`

* Default value: `/mnt/medialibrary/comics`

Description: This is the default folder where all comics are stored.

## MEDIADIR_MOVIES
* System Detected value: `~/Movies`

* Default value: `/mnt/medialibrary/movies`

Description: This is the default folder where all movies are stored. To be used with Radarr, Bazarr, etc.

## MEDIADIR_MUSIC
* System Detected value: `~/Music`

* Default value: `/mnt/medialibrary/music`

Description: This is the default folder where all movies are stored. To be used with Lidarr.

## MEDIADIR_TV
* System Detected value: `~/TV`

* Default value: `/mnt/medialibrary/tv`

Description: This is the default folder where all movies are stored. To be used with Sonarr, Bazarr, etc.

## PGID
* System Detected value: Detects the ID of your group

* Default value: `1000` because this is the most common default on supported OS

Description: This value can be obtained by using `id $user`.

## PUID
* System Detected value: Detects the ID of your user

* Default value: `1000` because this is the most common default on supported OS

Description: This value can be obtained by using `id $user`.

## TZ
* System Detected value: Uses the value found in `/etc/timezone`

* Default value: `America/Chicago` because that's @nemchik's timezone (CST)

## LAN_NETWORK
* System Detected value: Detects your local IP range.

* Default value: `192.168.x.x/24`

Description: Only accepts values in these ranges 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16.

## NS1
* Default value: `1.1.1.1`

Description:

## NS2
* Default value: `8.8.8.8`

Description:

## VPN_ENABLE
* Default value: `yes`

Description:

## VPN_OPTIONS
* Default value:

Description:

## VPN_OVPNDIR
* Default value: `~/.config/appdata/.openvpn`

Description: Directory where you will save your `ovpn` configuration so any VPN enabled containers use this VPN configuration.

## VPN_PASS
* Default value: No default

Description: This is the password you use to login to your VPN provider.

## VPN_PROV
* Default value: `custom`

Description:

## VPN_USER
* Default value: No default value

Description: This is the username you use to login with to your VPN provider.
