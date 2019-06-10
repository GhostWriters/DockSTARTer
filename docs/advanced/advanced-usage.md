Assuming you already followed the installation steps in the readme, there are also a number of command line switches you can use with DockSTARTer.

## Command Line Switches

#### Run the docker install script
```
sudo ds -i
```
This script does the following:
- Update your system using `apt-get`
- Install `curl`, `git`, `grep`, and `sed` (git should already be installed if you started at the top of this guide, but it's here just in case)
- Install [yq](https://github.com/mikefarah/yq) - by downloading the binary from source and installing it locally, used for piecing together YAML files
- Install [docker](https://github.com/docker/docker-install) - by downloading via the official docker-install script, used to run containers
- Install [docker machine completion](https://docs.docker.com/machine/completion/) - by downloading the binary from source and installing it locally, provides tab completion for docker in bash shell (just a nice extra to have)
- Install [docker-compose](https://docs.docker.com/compose/install/) OR [arm-compose](https://github.com/javabean/arm-compose) - by downloading the binary from source and installing it locally, allows configuring of containers to be run together instead of individually running each one
- Install [docker compose completion](https://docs.docker.com/compose/completion/) - by downloading the binary from source and installing it locally, provides tab completion for docker-compose in bash shell (just a nice extra to have)

When the script finishes it will prompt you to reboot.

#### Run the generator
```
sudo ds -c
```
This script verifies the dependencies above and installs or updates them as needed, then creates a file `~/.docker/compose/docker-compose.yml` based on the variables you configured in your `.env` file. The generator script will prompt to run your selected containers after creating the file.

We encourage you to have a look at the generated `docker-compose.yml` file, however if you wish to make changes please consider using overrides. Please review the [Technical Info](https://dockstarter.com/technical-info) and [Overrides](https://dockstarter.com/overrides) pages.

If you make any changes to your `.env` file (such as changing a port or enabling a new app) you need to rerun the generator which will rebuild only the affected containers.

#### To update DockSTARTer
```
sudo ds -u
```
This should get you the latest changes to DockSTARTer. Next you will want to ensure your `.env` file is updated as well:
```
sudo ds -e
```
Then you may want to edit your `.env` file and run the generator again to bring up new apps or changes to existing apps.

## Setup your environment
If you do not yet have a `~/.docker/compose/.env` file:
```
cd ~/.docker/compose
cp .env.example .env
```
Edit the file using something like `nano .env` (ctrl+x will prompt to save and exit the nano editor)

#### Universal Section
You will need to fill out all of variables in the top most **Universal** section.

You can find your **PUID** by running `id -u ${USER}`.

You can find your **PGID** by running `id -g ${USER}`.

Folders should be set to a location that actually exists even if you do not intend to use them (just make an empty folder and ignore it afterwards).

Inside **DOCKERCONFDIR**, a folder for each app will be created for it's configuration.

> * thanks to Patrick for letting us know!

**${TZ}** You should make sure your system's timezone is set correctly, and then also supply your timezone in the `TZ` variable (see [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)).

#### Application Specific Section

Navigate through the file and locate the `APPNAME_ENABLED` variables for the apps you wish to use and change their values from `false` to `true`.

You may also need to fill in or adjust any other variables prefixed with the `APPNAME_` that you're enabling.

* This is the best place to change your default ports.
* Please note, Portainer and Ouroboros are enabled by default. [Portainer](https://hub.docker.com/r/portainer/portainer/) provides a snazzy management interface at `your.ip.address:9000` and [Ouroboros](https://hub.docker.com/r/pyouroboros/uroboros/) checks for updates to the Containers you are using, __NOT__ DockSTARTer itself.
See [here](https://dockstarter.com/faq#ouroboros-and-portainer-i-didnt-select-them-but-they-installed-anyway) for a (little) more or you can disable them if you wish.

#### To clean up DockSTARTer any previous images at any time:
```
sudo ds -p
```
This cleans up the DS install, p stands for prune in this case. This recovers space from old images if they were somehow left over.

#### What is this appdata thing?

If you've heard other people talk about an `appdata` folder and not been sure what they meant, it's what we have had as our default `~/.docker/config` since the beginning of DockSTARTer.

As of today that has changed. For new installs the default `DOCKERCONFDIR` will be `~/.config/appdata` instead of `~/.docker/config`. For existing users nothing changes! You can keep your config folder right where it is.

If you'd like to move your existing config to the new default location (even though you don't have to) you can do the following:
Edit `~/. docker/compose/.env` (in any text editor) and set
```
DOCKERCONFDIR=~/.config/appdata
```
And
```
DOCKERSHAREDDIR=~/.config/appdata/shared
```
If you're using duplicati you will also need to set
```
DUPLICATI_BACKUPSDIR=~/.config/appdata/backups
DUPLICATI_SOURCEDIR=~/.config/appdata
```
(Unless you have these set somewhere else on purpose). Then run the following commands:
```
ds -u
ds -c down
sudo mv ~/.docker/config ~/.config/appdata
ds -c
```
That's it! Your containers should fire right back up as if nothing has changed. If you have any issues feel free to ask for help in #ds-support
