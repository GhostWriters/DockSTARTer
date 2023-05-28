# OpenMediaVault (OMV)

OpenMediaVault (OMV) requires some special setup in order to install DockSTARTer (DS). DS staff have tested and confirmed the following installation method on OMV version 5.5.

If you are a Linux newbie, we _strongly discourage_ this approach because of all the issues that might arise with how OMV is built, and troubleshooting issues in OMV can be a pain. However, if you feel comfortable with Linux and want to continue down this route you will need to ensure the following:

- You have installed all the necessary updates that are pending in your system.
- You have set a DNS server in your Web GUI.
- You have created a user **with a home directory** outside of the system disk that has `sudo` and `ssh` permissions. See below in how to do that.
- You have a secondary disk other than the system drive mounted and formatted to anything other than NTFS.
- We recommend you set up a specific "Shared Folder" for your home directory. `appdata` directory should **only** be used to store container configurations, not home directories.

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
