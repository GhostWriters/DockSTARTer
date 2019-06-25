# FAQ

## Ouroboros and Portainer: I didn't select them but they installed anyway?

They are installed by default and the below blurbs from their official documentation should explain why but you can disable either or both of them if you want.

> [Ouroboros](https://hub.docker.com/r/pyouroboros/ouroboros/) will monitor (all or specified) running docker containers and update them to the (latest or tagged) available image in the remote registry.
>
> [Portainer](https://hub.docker.com/r/portainer/portainer/) allows you to manage your Docker stacks, containers, images, volumes, networks and more! It is compatible with the standalone Docker engine and with Docker Swarm.

In short, Ouroboros keeps your Containers up to date and Portainer gives you a WebGUI for starting and stopping Containers. Have a look, at `www.appropriateaddress.com:9000` .

DockSTARTer previously enabled Watchtower by default before Ouroboros. The two do almost the same thing, but Ouroboros has more options.

## General troubleshooting help

You can see the (quite helpful) logs of each container with a Quick action in Portainer:
![Portainer log quick action](https://gist.github.com/juligreen/aaf72244b8b4a9c09fc80112ba25e79d/raw/05b94051569fa4fc3c73593069de6293af5dfa50/Portainer%2520quick.PNG)

## Reported Issues

### Creating network "compose_default" with the default driver ERROR: could not find an available, non-overlapping IPv4 address pool among the defaults to assign to the network

This error can occur if your connected to a VPN while setting up the containers. Simply temporarily disconnect your VPN connection until the containers have been created and then reconnect again.

### Starting containers and getting the following or a similar error message: "listen udp 0.0.0.0:5353: bind: address already in use"

As you could probably guess this means an application (most likely plex) is trying to use a port that is already in use.
You can check which application it is with:

```bash
sudo lsof -i :<myport>
```

So in this example it would be:

```bash
sudo lsof -i :5353
```

which will show you that Google Chrome is using the port you need. In this case you could just close Chrome, but there may be applications you need to uninstall for this to work properly.
