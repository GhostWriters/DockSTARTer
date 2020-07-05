# FAQ

## Ouroboros And Portainer Enabled By Default

These tools are extremely useful for people getting used to running docker. Their official documentation should explain why but you can disable either or both of them if you want.

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

## OpenMediaVault (OMV)

We have had a recent influx of users asking for assistance in how to make OMV work with DockSTARTer (DS). DS staff have tested and confirmed the following installation method on OMV version 5.5.

If you are a Linux noobie, we *discourage* this approach because of all the issues that might arise with how OMV is built, and troubleshooting issues in OMV can be a pain. However, if you feel comfortable with Linux and want to continue down this route you will need to ensure the following:

1. You have created a user **with a home directory** that has `sudo` and `ssh` permissions. **It cannot be the root account.**

2. You have another disk other than the system drive with all shared folders necessary for DS set up. These folders include `/appdata`, `/downloads`, `/media` and lastly `/home`.

3. We recommend you set up a specific "Shared Folder" for your home directory. `appdata` directory should **only** be used to store container configurations, not home directories.

Once the above requirements have been met, you will need to SSH to your OMV host using the account you created. First make sure your home directory was set up correctly by typing `cd ~`. This shouldn't return an error, if it does read over the OMV documentation in how to properly create a user with a home directory.

As usual, make sure all applicable updates have been installed and run each of these commands:

`sudo apt-get install curl git`
`bash -c "$(curl -fsSL https://get.dockstarter.com)"`
`sudo reboot`

After rebooting, go ahead and SSH back to your host, and run `sudo ds`, you will get a `permission denied` error. This is expected and part of how OMV is configured. You will need to edit a system config file in order to get around this error. Run the following command (you can use your favorite text editor for this portion):

`sudo nano /etc/openmediavault/config.xml`

You need to find line number 370. It will have the following string:

`<opts>defaults,nofail,user_xattr,noexec,usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv0,acl...`

The part you care about is the `noexec` bit. You will need to remove that. Save the file.

Because OMV is OMV, this step messes up permissions on the shared folders you created so you will need to go on your Web GUI and clear all ACLs on each of those folders to avoid issues in the future. We recommend you use `openmediavault-resetperms` plugin from OMV-Extras tp reset the permissions directly from the Web GUI unless you like doing things from the terminal in OMV.

After you reset the permissions, OMV throws another curveball and if you try to run `sudo ds` or `ds` it will tell you "not found". So, now you have to run `bash -c "$(curl -fsSL https://get.dockstarter.com)"` one last time and voila! DS works.
