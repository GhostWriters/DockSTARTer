---
layout: default
---

## What Is DockSTARTer ?
DockSTARTer is a program that starts a bunch of different containers within a common framework to make it easy to install all your favorite apps and tools.


## System Requirements
### Supported Operating Systems
We imagine DockSTARTer will behave nicely on any systems supported by the https://get.docker.com/ script. Your experiences with individual containers may vary though based primarily on the availability of the container for your hardware architecture.

### Supported Hardware
Raspberry Pi or better? ARM architecture will be limited compared to x86_64 as far as app selection.
### Windows Support?
Have you considered a Virtual Machine? Windows 8.1 has VM support built in. This has some benefits over running the same programs on windows, it allows you to essentially "sandbox" all your apps and best of all, you'll have a reason to still be here!

[Read this guide here](https://www.windowscentral.com/how-run-linux-distros-windows-10-using-hyper-v) to get up and running with Linux essentially running as a app within Windows. Just remember to get the server ISO, Linux is generally pretty lean but an idle fresh install of Ubuntu (server) uses less than 200mb of memory and about 5gb minimum storage.

## Ouroboros and Portainer: I didn't select them but they installed anyway?
They are installed by default and the below blurbs from their official documentation should explain why but you can disable either or both of them if you want.

> [Ouroboros](https://hub.docker.com/r/pyouroboros/ouroboros/) will monitor (all or specified) running docker containers and update them to the (latest or tagged) available image in the remote registry.

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
```
sudo lsof -i :<myport>
```
So in this example it would be:
```
sudo lsof -i :5353
```
which will show you that Google Chrome is using the port you need. In this case you could just close Chrome, but there may be applications you need to uninstall for this to work properly.
