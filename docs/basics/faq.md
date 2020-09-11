# FAQ

## Support

Refer to our [Support Page](https://dockstarter.com/basics/support/) for our Support Channels and Tutorials we have found users have made with DockSTARTer!

## Relocating `appdata`

If you've heard other people talk about an `appdata` folder and not been sure what they meant, it's what we have had as our default `~/.docker/config` since the beginning of DockSTARTer.

As time went on, we realized it was more effective to separate `appdata` from the overall `compose` directory. For new installs the default `DOCKERCONFDIR` will be `~/.config/appdata` instead of `~/.docker/config`. For existing users nothing changes! You can keep your config folder right where it is.

If you'd like to move your existing config to the new default location (even though you don't have to) you can do the following:
Edit `~/. docker/compose/.env` (in any text editor) and set

```bash
DOCKERCONFDIR=~/.config/appdata
```

And

```bash
DOCKERSHAREDDIR=~/.config/appdata/shared
```

(Unless you have these set somewhere else on purpose). Then run the following commands:

```bash
ds -u
ds -c down
sudo mv ~/.docker/config ~/.config/appdata
ds -c
```

That's it! Your containers should fire right back up as if nothing has changed. If you have any issues feel free to ask for help in #ds-support

## Ouroboros Enabled By Default

This tool is extremely useful for people getting used to running Docker. It's official documentation should explain why but you can disable it if you want.

> [Ouroboros](https://hub.docker.com/r/pyouroboros/ouroboros/) will monitor (all or specified) running docker containers and update them to the (latest or tagged) available image in the remote registry.

In short, Ouroboros keeps your containers up to date.

DockSTARTer previously enabled Watchtower by default before Ouroboros. The two do almost the same thing, but Ouroboros has more options.

## Ouroboros/Watchtower FAQ

### When I run `ds -c` and it recreates some of the containers, is that because they have had updates from last run

With Ouroboros (or Watchtower) your containers will be updated to the latest images automatically. However, docker-compose has no idea what's updated, docker-compose keeps track of things independently from Ouroboros/Watchtower. Additionally, Ouroboros/Watchtower don't update docker-compose's method of tracking, therefore, compose might "recreate" containers that are already up to date. This is not a big deal it's basically just a container restart, and you were planning on running `ds -c` expecting some kind of updates anyway.

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

## OpenMediaVault (OMV)

We have had a recent influx of users asking for assistance in how to make OMV work with DockSTARTer (DS). DS staff have tested and confirmed the following installation method on OMV version 5.5.

If you are a Linux newbie, we *strongly discourage* this approach because of all the issues that might arise with how OMV is built, and troubleshooting issues in OMV can be a pain. However, if you feel comfortable with Linux and want to continue down this route you will need to ensure the following:

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

We are now going to work on creating the directories for DS to use. You will need to create 4 shared folders and allow "Everyone read/write". The 4 directories will be called `appdata`, `storage`, `medialibrary` and `home`.

The last directory should be where you store your user directories and you should not be using the system disk for that. If you do not know how to create a user and assign it a home directory; look up the OMV documentation as that is outside of the scope of this guide.

Once the above requirements have been met, you will need to SSH to your OMV host using the account you created. First make sure your home directory was set up correctly by typing `cd ~`. This shouldn't return an error, if it does read over the OMV documentation in how to properly create a user with a home directory. If no error occurs, run the following commands:

`sudo apt-get install curl git`
`bash -c "$(curl -fsSL https://get.dockstarter.com)"`
`sudo reboot`

After the reboot is complete, SSH back to your host using your user account and run `ds`, type your password and select "Configuration". Select "Set Global Variables" and select "No" on the next prompt. The only thing we recommend changing is the `PGID` to `Use System 100`. On the next screen, please take note of the path that starts with `/srv/dev-disk-by-label-XXX`. You are going to want to remember this path to set your `appdata`, `storage`, `media` and `downloads` folder to that path, for instance: `/srv/dev-disk-by-label-DS/appdata/`, `/srv/dev-disk-by-label-DS/media/movies`, etc.
