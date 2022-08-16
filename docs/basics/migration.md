# Migration

## From local installs

- Stop the service for the existing app (so that ports are available)
- Start the app using TrunkSTARTer so that the config folder structure is created (`~/.config/trunkdata/<appname>` by default)
- Stop the app's docker container (`docker stop <appname>`)
- Locate the config of the local installation and copy it to `~/.config/trunkdata/<appname>` (only grab the required files)
- Start the app (`sudo ts -c`)
- Inside the app's config, or settings web interface, adjust the folder locations that make use of files on the disk to match the docker volumes for the container
- Adjust the app config to communicate with other existing apps (both in and out of docker as needed)
- Optionally uninstall/remove original app and dependencies

## From other Docker containers

- Stop the app's old docker container
- Start the app using DockSTARTer so that the config folder structure is created (`~/.config/trunkdata/<appname>` by default)
- Stop the app's new docker container (`docker stop <appname>`)
- Locate the config of the old docker container and copy it to `~/.config/trunkdata/<appname>` (only grab the required files)
- Start the app (`sudo ts -c`)
- Inside the app's config, or settings web interface, adjust the folder locations that make use of files on the disk to match the docker volumes for the new container
- Adjust the app config to communicate with other existing apps (both in and out of docker as needed)
- Remove the app's old docker container

