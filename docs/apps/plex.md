# Plex

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/plex?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/plex)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-plex?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-plex)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/plex)

## Description

[Plex](https://plex.tv/) organizes video, music and photos from personal media libraries and streams them to smart TVs, streaming boxes and mobile devices. This container is packaged as a standalone Plex Media Server. has always been a top priority. Straightforward design and bulk actions mean getting things done faster.

## Install/Setup

### Common Issue: Playback fails for certain media

One possible resolution to this issue is to remove the codecs folder:

```bash
rm -rf "~/.config/appdata/plex/Library/Application Support/Plex Media Server/Codecs"
```

Or place a custom init script in your config (ex: `~/.config/appdata/plex/custom-cont-init.d/00-plex-remove-codecs`):

```bash
#!/usr/bin/with-contenv bash
set -euo pipefail
IFS=$'\n\t'

rm -rf "/config/Library/Application Support/Plex Media Server/Codecs"
echo "Codecs removed."
```

This will run every time the container restarts.

### Common Issue: Cannot Claim Server on First Run

If you are starting the Plex container for the first time and cannot claim your server to set it up there are 3 methods you can try to resolve the issue:

#### 1. Set the PLEX_CLAIM variable

```bash
docker stop plex
docker rm plex
```

```bash
# removes the config folder for plex
# !WARNING! do NOT do this if you have already setup your plex server and are having issues connecting to it, skip to option 3 instead
rm -rf ~/.config/appdata/plex
```

```bash
sudo nano ~/.docker/compose/.env
# with the nano file editor open locate the PLEX_CLAIM variable
# go to https://www.plex.tv/claim/ in your browser and get the claim token set your PLEX_CLAIM variable
# the token expires in 5 minutes, so we'll want to get the rest done quickly
# ctrl+x to save and exit nano
```

```bash
ds -c up plex
```

Then try again to claim the server by visiting `http://yourserverip:32400/web/index.html`

#### 2. Host Network Mode

If the first method does not work, edit your `.env` and set `PLEX_NETWORK_MODE=host`. Run `ds -c` and then attempt to claim your server. After claiming your server set `PLEX_NETWORK_MODE=` (back to blank).

#### 3. Claim helper script

If the first and second methods both have not worked this script should make it happen.

```bash
docker exec -it plex /bin/bash
```

```bash
# download the script
curl -L -o plex-claim-server.sh https://github.com/uglymagoo/plex-claim-server/raw/master/plex-claim-server.sh
```

```bash
# make the script executable
chmod +x plex-claim-server.sh
```

```bash
# go to https://www.plex.tv/claim/ in your browser and get the claim token and replace PLEX_CLAIM with this token in the next command, please use use the double quotes around your claim token
./plex-claim-server.sh "PLEX_CLAIM"
```

```bash
# fix permissions
chown abc:abc "/config/Library/Application Support/Plex Media Server/Preferences.xml"
```

```bash
# leave the container
exit
```

```bash
docker restart plex
```

### How To Run Plex Different Pass Versions

Edit `~/.docker/compose/.env` and set:

```bash
PLEX_VERSION=plexpass
```

Then run:

```bash
ds -c up plex
```

### Rebuilding From Scratch

Thankfully, some of this information is well documented (but not easily found) over on Plex's website here!

- Moving an installation to another system: [https://support.plex.tv/articles/201370363-move-an-install-to-another-system/](https://support.plex.tv/articles/201370363-move-an-install-to-another-system/)
- Where is the Plex Media Server data directory? [https://support.plex.tv/articles/202915258-where-is-the-plex-media-server-data-directory-located/](https://support.plex.tv/articles/202915258-where-is-the-plex-media-server-data-directory-located/)

### Hardware Transcoding

If you would like to have Plex use a GPU that is attached to your DockSTARTer host, you can do this using an [override](https://dockstarter.com/overrides/introduction/) like so:

```yaml
  plex:
    devices:
      - /dev/dri:/dev/dri
```

Refer to this forum post for details: [Using Hardware Acceleration in Docker](https://forums.plex.tv/t/using-hardware-acceleration-in-docker/229702/3)

### Using fast or large storage for specific Plex configs

By default Plex will Cache, Log, Transcode, and store metadata to the config folder for Plex (usually `~/.config/appdata/plex/`). You may wish to use other disks that are faster, or have more space available for these things. You can do this using an [override](https://dockstarter.com/overrides/introduction/) like so:

```yaml
  plex:
    volumes:
      - "/mnt/fastDisk/cache:/config/Library/Application Support/Plex Media Server/Cache"
      - "/mnt/bigDisk/logs:/config/Library/Application Support/Plex Media Server/Logs"
      - "/mnt/bigDisk/media:/config/Library/Application Support/Plex Media Server/Media"
      - "/mnt/bigDisk/metadata:/config/Library/Application Support/Plex Media Server/Metadata"
      - "/mnt/fastDisk/transcode:/config/Library/Application Support/Plex Media Server/Cache/Transcode/Sessions"
```

These volumes are all optional. If your config folder runs on an SSD with enough space you might not need any of them. If your config is stored on an SSD with very little space, you might only relocate the ones above that mention `bigDisk`. If your config is stored on a slower disk with plenty of space you might only relocate the ones above that mention `fastDisk`.
