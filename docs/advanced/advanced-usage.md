# Advanced Usage

Assuming you already followed the installation steps in the readme, there are also a number of command line switches you can use with DockSTARTer.

## Command Line Switches

### Run The Install Script

```bash
sudo ds -i
```

This script does the following:

- Update your system using `apt-get`
- Install `curl`, `git`, `grep`, and `sed` (git should already be installed if you started with the install instructions on the main page, but it's here just in case)
- Install [yq](https://github.com/mikefarah/yq) - by downloading the binary from source and installing it locally, used for piecing together YAML files
- Install [docker](https://github.com/docker/docker-install) - by downloading via the official docker-install script, used to run containers
- Install [docker machine completion](https://docs.docker.com/machine/completion/) - by downloading the binary from source and installing it locally, provides tab completion for docker in bash shell (just a nice extra to have)
- Install [docker-compose](https://docs.docker.com/compose/install/) - using python3 pip, allows configuring of containers to be run together instead of individually running each one
- Install [docker compose completion](https://docs.docker.com/compose/completion/) - by downloading the binary from source and installing it locally, provides tab completion for docker-compose in bash shell (just a nice extra to have)

When the script finishes it will prompt you to reboot.

### Run The Compose Generator

```bash
sudo ds -c
```

This script verifies the dependencies above and installs or updates them as needed, then creates a file `~/.docker/compose/docker-compose.yml` based on the variables you configured in your `~/.docker/compose/.env` file. The generator script will prompt to run your selected containers after creating the file.

We encourage you to have a look at the generated `docker-compose.yml` file, however if you wish to make changes please consider using overrides. Please review the [Technical Info](https://dockstarter.com/advanced/technical-info) and [Overrides / Introduction](https://dockstarter.com/overrides/introduction) pages.

If you make any changes to your `.env` file (such as changing a port or enabling a new app) you need to rerun the generator which will rebuild only the affected containers.

### Update DockSTARTer

```bash
sudo ds -u
```

This should get you the latest changes to DockSTARTer. This will also backup and update your `.env` file.

You may separately backup and update your `.env` file with the following command.

```bash
sudo ds -e
```

Then you may want to edit your `.env` file and run the generator again to bring up new apps or changes to existing apps.

## Setup Your Environment

If you do not yet have a `~/.docker/compose/.env` file:

```bash
sudo ds -e
```

Edit the file using something like `nano ~/.docker/compose/.env` (ctrl+x will prompt to save and exit the nano editor)

### Universal Section

You will need to fill out all of variables in the top most **Universal** section.

You can find your **PUID** by running `id -u ${USER}`.

You can find your **PGID** by running `id -g ${USER}`.

Folders should be set to a location that actually exists even if you do not intend to use them (just make an empty folder and ignore it afterwards).

Inside **DOCKERCONFDIR**, a folder for each app will be created for it's configuration.

**${TZ}** You should make sure your system's timezone is set correctly, and then also supply your timezone in the `TZ` variable (see [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)).

### Application Variables

#### Adding Apps

You can add the variables required to run an app by running:

```bash
# sudo ds -a <APPNAME>
## Example:
sudo ds -a sonarr
```

Then your `.env` file fill have a variable named `APPNAME_ENABLED` that you can `true` and then run the Compose Generator to start the app.

You may also need to fill in or adjust any other variables prefixed with the `APPNAME_` that you're enabling.

This is the best place to change your default ports.

Please note, Ouroboros is enabled by default. [Ouroboros](https://hub.docker.com/r/pyouroboros/uroboros/) checks for updates to the Containers you are using, __NOT__ DockSTARTer itself.
See [here](https://dockstarter.com/faq) for a (little) more or you can disable it if you wish.

#### Removing Apps

You can remove the variables for an app by running:

```bash
# sudo ds -r <APPNAME>
## Example:
sudo ds -r sonarr
```

You can also remove all variables for all apps that are disabled by running:

```bash
sudo ds -r
```

You will be prompted individually for each app and shown what will be removed.

### Cleanup Unused Docker Resources

```bash
sudo ds -p
```

This cleans up the DS install, p stands for prune in this case. This recovers space from old images if they were somehow left over.

### What is `appdata`

If you've heard other people talk about an `appdata` folder and not been sure what they meant, it's what we have had as our default `~/.docker/config` since the beginning of DockSTARTer.

As of today that has changed. For new installs the default `DOCKERCONFDIR` will be `~/.config/appdata` instead of `~/.docker/config`. For existing users nothing changes! You can keep your config folder right where it is.

If you'd like to move your existing config to the new default location (even though you don't have to) you can do the following:
Edit `~/. docker/compose/.env` (in any text editor) and set

```bash
DOCKERCONFDIR=~/.config/appdata
```

And

```bash
DOCKERSTORAGEDIR=~/storage
```

If you're using duplicati you will also need to set

```bash
DUPLICATI_BACKUPSDIR=~/.config/appdata/backups
DUPLICATI_SOURCEDIR=~/.config/appdata
```

(Unless you have these set somewhere else on purpose). Then run the following commands:

```bash
ds -u
ds -c down
sudo mv ~/.docker/config ~/.config/appdata
ds -c
```

That's it! Your containers should fire right back up as if nothing has changed. If you have any issues feel free to ask for help in #ds-support
