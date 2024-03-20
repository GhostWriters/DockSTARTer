# FAQ

## Support

Refer to our [Support Page](https://dockstarter.com/basics/support/) for our Support Channels and Tutorials we have found users have made with DockSTARTer!

## Relocating `appdata`

For new installs the default `DOCKER_VOLUME_CONFIG` is `~/.config/appdata`. Users who ran DockSTARTer before this location became the default may have `~/.docker/config`, and we advise relocating.

If you'd like to move your existing config to a new location you can do the following:
Edit `~/. docker/compose/.env` (in any text editor) and set

```bash
DOCKER_VOLUME_CONFIG=~/.config/appdata
```

(You can choose anywhere to save configs, this example only shows the default location).

Then run the following commands:

```bash
ds -u
ds -c down
# Move your current config folder to the new location, ex:
sudo mv ~/.docker/config ~/.config/appdata
ds -c
```

That's it! Your containers should fire right back up as if nothing has changed. If you have any issues feel free to ask for help in `#ds-support`

## Watchtower Enabled By Default

This tool is extremely useful for people getting used to running Docker. Its official documentation should explain why but you can disable it if you want.

> [Watchtower](https://hub.docker.com/r/containrrr/watchtower) will pull down your new image, gracefully shut down your existing container and restart it with the same options that were used when it was deployed initially.

In short, Watchtower keeps your containers up to date.

## Watchtower FAQ

### When I run `ds -c` and it recreates some of the containers, is that because they have had updates from last run

With Watchtower your containers will be updated to the latest images automatically. However, docker-compose has no idea what's updated, docker-compose keeps track of things independently from Watchtower. Additionally, Watchtower doesn't update docker-compose's method of tracking, therefore, compose might "recreate" containers that are already up to date. This is not a big deal it's basically just a container restart, and you were planning on running `ds -c` expecting some kind of updates anyway.

## General troubleshooting help

You can see the (quite helpful) logs of each container with the `docker logs <appname>` command.

Additionally, you can also use [Dozzle](https://dockstarter.com/apps/dozzle/) if you prefer to view logs using your browser.

## Reported Issues

### Creating network "compose_default" with the default driver ERROR: could not find an available, non-overlapping IPv4 address pool among the defaults to assign to the network

This error can occur if your connected to a VPN while setting up the containers. Simply temporarily disconnect your VPN connection until the containers have been created and then reconnect again.

### Starting containers and getting the following or a similar error message: "listen udp 0.0.0.0:5353: bind: address already in use"

As you could probably guess this means an application (most likely Plex) is trying to use a port that is already in use.
You can check which application it is with:

```bash
sudo lsof -i :<myport>
```

So in this example it would be:

```bash
sudo lsof -i :5353
```

which will show you that Google Chrome is using the port you need. In this case you could just close Chrome, but there may be applications you need to uninstall for this to work properly.
