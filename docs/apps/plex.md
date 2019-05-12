---
layout: default
---

### Plex is telling me to login and then not directing me to the server I just set up, why?
Upon starting up Plex for the first time, it's very likely you'll need to follow these steps:
> **NOTE - You have 5 minutes from the time you generate your Claim Token to get Plex back up and running, so you may need to work fast!)**
1. Run `docker stop plex && docker rm plex`
2. Run `mv ~/.config/appdata/plex/ ~/.config/appdata/plex.bak/`
3. Grab your Plex Claim Token from here: [https://www.plex.tv/claim](https://www.plex.tv/claim)
4. Edit `~/.docker/compose/.env`
5. Set `PLEX_CLAIM=` to use the claim token you generated from the link.
6. Run `sudo ds -c up`
7. Go back to http://x.x.x.x:32400/web (x.x.x.x being the IP of your Plex server) and you should be able to complete FTS.

If the above does not work repeat the steps a second time but also with step 4 in your `.env` set `PLEX_NETWORK_MODE=host`. After claiming your server set `PLEX_NETWORK_MODE=` (back to blank).

### Everything's gone to crap, and I need to re-make my server. What do I do?
Thankfully, some of this information is well documented (but not easily found) over on Plex's website here!
1. Moving an installation to another system: [https://support.plex.tv/articles/201370363-move-an-install-to-another-system/](https://support.plex.tv/articles/201370363-move-an-install-to-another-system/)
2. Where is the Plex Media Server data directory? [https://support.plex.tv/articles/202915258-where-is-the-plex-media-server-data-directory-located/](https://support.plex.tv/articles/202915258-where-is-the-plex-media-server-data-directory-located/)

If you would like to have Plex use a GPU that is attached to your DockSTARTer host, you can do this using an override like so:
```
devices:
     - /dev/dri:/dev/dri
```
Refer to this forum post for details: [Using Hardware Acceleration in Docker](https://forums.plex.tv/t/using-hardware-acceleration-in-docker/229702/3)
