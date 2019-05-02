---
layout: default
---

## Migrating from local installs

- Stop the service for the existing app (so that ports are available)
- Start the app using DockSTARTer so that the config folder structure is created (`~/.docker/config/appname` by default)
- Stop the app's docker container (`docker stop appname`)
- Locate the config of the local installation and copy it to `~/.docker/config/appname` (only grab the required files)
- Start the app (`sudo ds -c`)
- Inside the app's config, or settings web interface, adjust the folder locations that make use of files on the disk to match the docker volumes for the container
- Adjust the app config to communicate with other existing apps (both in and out of docker as needed)
- Optionally uninstall/remove original app and dependencies

## Example

Sonarr's config is commonly found in `~/.config/NzbDrone`. Following the instructions above, all files in `~/.config/NzbDrone` would be copied to `~/.docker/config/sonarr`. After starting the new Sonarr in Docker, modify the Root Folder settings to tell Sonarr where your files are. DockSTARTer maps the true location of your media folders to locations the container expects to see such as `/tv` in the case of Sonarr, so that is where you will set your root folder. You will also need to modify your settings that have Sonarr connect to other apps such as Usenet or Torrent download clients. Rather than an IP address or `localhost` you would just use the name of the download client app, ex: `nzbget` as the hostname. The same would apply for any connections between any app.
