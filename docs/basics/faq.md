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

If you are a Linux noobie, we *strongly discourage* this approach because of all the issues that might arise with how OMV is built, and troubleshooting issues in OMV can be a pain. However, if you feel comfortable with Linux and want to continue down this route you will need to ensure the following:

1. You have installed all the necessary updates that are pending in your system.

2. You have set a DNS server in your Web GUI.

3. You have created a user **with a home directory** outside of the system disk that has `sudo` and `ssh` permissions. See below in how to do that.

4. You have a secondary disk other than the system drive mounted and formatted to anything other than NTFS.

5. We recommend you set up a specific "Shared Folder" for your home directory. `appdata` directory should **only** be used to store container configurations, not home directories.

**SSH to your host as root.** You will need to edit a system config file in order to avoid issues in the future. Run the following command (you can use your favorite text editor for this portion):

`nano /etc/openmediavault/config.xml`

We are looking for the following line:

`<opts>defaults,nofail,user_xattr,noexec,usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv0,acl...`

The part you care about is the `noexec` bit. You will need to remove that string. Save the file and per [OMV documentation](https://openmediavault.readthedocs.io/en/5.x/various/fs_env_vars.html) you need to run `omv-salt deploy run fstab`. To verify that the `noexec` flag was removed from your drive run `cat /proc/mounts` and find your drive on the list. You can also run `cat /proc/mounts | grep partial_drive_name`. If the `noexec` flag is present, you skipped a step.

We are now going to work on creating the directories for DS to use. You will need to create 4 shared folders and allow "Everyone read/write". The 4 directories will be called `appdata`, `shared`, `medialibrary` and `home`.

The last directory should be where you store your user directories and you should not be using the system disk for that. If you do not know how to create a user and assign it a home directory; look up the OMV documentation as that is outside of the scope of this guide.

Once the above requirements have been met, you will need to SSH to your OMV host using the account you created. First make sure your home directory was set up correctly by typing `cd ~`. This shouldn't return an error, if it does read over the OMV documentation in how to properly create a user with a home directory. If no error occurs, run the following commands:

`sudo apt-get install curl git`
`bash -c "$(curl -fsSL https://get.dockstarter.com)"`
`sudo reboot`

After the reboot is complete, SSH back to your host using your user account and run `ds`, type your password and select "Configuration". Select "Set Global Variables" and select "No" on the next prompt. The only thing we recommend changing is the `PGID` to `Use System 100`. On the next screen, please take note of the path that starts with `/srv/dev-disk-by-label-XXX`. You are going to want to remember this path to set your `appdata`, `shared`, `media` and `downloads` folder to that path, for instance: `/srv/dev-disk-by-label-DS/appdata/`, `/srv/dev-disk-by-label-DS/media/movies`, etc.
