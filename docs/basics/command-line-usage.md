# Command Line Usage

Assuming you already followed the installation steps in the readme, there are also a number of command line switches you can use with TrunkSTARTer.

## Command Line Switches

### Run The Install Script

```bash
sudo ts -i
```

This script does the following:

- Updates your system using `apt-get`
- Installs `curl`, `git`, `grep`, and `sed` (git should already be installed if you started with the install instructions on the main page, but it's here just in case)
- Installs [docker](https://github.com/docker/docker-install) - by downloading via the official docker-install script, used to run containers

When the script finishes it will display a message informing you to reboot if this is the first time you've ran it.

### Run The Compose Generator

```bash
sudo ts -c
```

This script verifies the dependencies above and installs or updates them as needed, then creates a file `~/.docker/compose/docker-compose.yml` based on the variables you configured in your `~/.docker/compose/.env` file. The generator script will run your selected containers after creating the file.

We encourage you to have a look at the generated `docker-compose.yml` file, however if you wish to make changes please consider using overrides. Please review the [Technical Info](https://trunkstarter.com/advanced/technical-info) and [Overrides / Introduction](https://trunkstarter.com/overrides/introduction) pages.

If you make any changes to your `.env` file (such as changing a port or enabling a new app) you need to rerun the generator which will rebuild only the affected containers.

### Update DockSTARTer

```bash
sudo ts -u
```

This should get you the latest changes to TrunkSTARTer. This will also backup and update your `.env` file.

You may separately backup and update your `.env` file with the following command.

```bash
sudo ts -e
```

Then you may want to edit your `.env` file and run the generator again to bring up new apps or changes to existing apps.

## Setup Your Environment

If you do not yet have a `~/.docker/compose/.env` file:

```bash
sudo ts -e
```

Edit the file using something like `nano ~/.docker/compose/.env` (CTRL+X will prompt to save and exit the nano editor)

### Application Specific Variables

#### Adding Apps

You can add the variables required to run an app by running:

```bash
sudo ts -a <APPNAME>
```

```bash
## Example:
sudo ts -a trunk-recorder
```

Then your `.env` file fill have a variable named `<APPNAME>_ENABLED` that you can set to `true` and then run the Compose Generator to start the app.

You may also need to fill in or adjust any other variables prefixed with the `<APPNAME>_` that you're enabling.

This is the best place to change the app's external default ports.

#### Removing Apps

You can remove the variables for an app by running:

```bash
sudo ts -r <APPNAME>
```

```bash
## Example:
sudo ts -r trunk-recorder
```

You can also remove all variables for all apps that are disabled by running:

```bash
sudo ts -r
```

You will be prompted individually for each app and shown what will be removed.

### Cleanup Unused Docker Resources

```bash
sudo ts -p
```

This cleans up the TS install, `p` stands for prune in this case. This recovers space from old images if they were somehow left over.
