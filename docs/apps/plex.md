# Plex

## Cannot Claim Server On First Run

Upon starting up Plex for the first time, it's very likely you'll need to follow these steps:

```bash
docker exec -it plex /bin/bash

# download the script
curl -L -o plex-claim-server.sh https://github.com/uglymagoo/plex-claim-server/raw/master/plex-claim-server.sh
# make the script executable
chmod +x plex-claim-server.sh
# go to https://www.plex.tv/claim/ in your browser and get the claim token and replace PLEX_CLAIM with this token in the next command, please use use the double quotes around your claim token
./plex-claim-server.sh "PLEX_CLAIM"
# fix permissions
chown abc:abc "/config/Library/Application Support/Plex Media Server/Preferences.xml"
# leave the container
exit

docker restart plex
```

Alternatively if that doesn't work, try:

Edit `~/.docker/compose/.env` and set `PLEX_NETWORK_MODE=host`. After claiming your server set `PLEX_NETWORK_MODE=` (back to blank).

## How To Run Plex Pass Versions

Edit `~/.docker/compose/.env` and set:

```bash
PLEX_VERSION=plexpass
```

Then run `ds -c`

## Rebuilding From Scratch

Thankfully, some of this information is well documented (but not easily found) over on Plex's website here!

1. Moving an installation to another system: [https://support.plex.tv/articles/201370363-move-an-install-to-another-system/](https://support.plex.tv/articles/201370363-move-an-install-to-another-system/)
1. Where is the Plex Media Server data directory? [https://support.plex.tv/articles/202915258-where-is-the-plex-media-server-data-directory-located/](https://support.plex.tv/articles/202915258-where-is-the-plex-media-server-data-directory-located/)

## Hardware Transcoding

If you would like to have Plex use a GPU that is attached to your DockSTARTer host, you can do this using an override like so:

```yaml
  plex:
    devices:
      - /dev/dri:/dev/dri
```

Refer to this forum post for details: [Using Hardware Acceleration in Docker](https://forums.plex.tv/t/using-hardware-acceleration-in-docker/229702/3)
