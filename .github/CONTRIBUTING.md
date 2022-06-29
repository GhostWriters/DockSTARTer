# Contributing

All code in this repository should be neat and tidy.

More important than being beautiful is being functional. This repository is primarily shell scripts and YAML files.

We use [GitHub Actions](https://github.com/GhostWriters/DockSTARTer/actions) to run [checks](https://github.com/GhostWriters/DockSTARTer/tree/master/.github/workflows) on the code in the repository. Code must pass checks run by GitHub Actions in order to merge to the `master` branch of the repository.

Try not to [code like a cowboy](https://en.wikipedia.org/wiki/Cowboy_coding).

## Setting up your Dev Environment

1. Fork this repository and clone it onto your system. In later steps we'll refer to the location of your local repository as `/path/to/your/ds-repo`
1. Install DockSTARTer
1. Delete the DockSTARTer installed docs folder so we can create a symlink in the next step:  `rm -rf ~/.docker/docs`
1. Point DockSTARTer to the docs directory in your cloned repo: `ln -s /path/to/your/ds-repo/docs ~/.docker/docs`
1. Delete the DockSTARTer installed .apps folder so we can create a symlink in the next step: `rm -rf ~/.docker/compose/.apps`
1. Point DockSTARTer to the .apps directory in your cloned repo: `ln -s /path/to/your/ds-repo/compose/.apps ~/.docker/compose/.apps`

You should now have an environment where the DockSTARTer GUI and CLI use files you are editing in your local git repository. Eg. if you add a new app into `/path/to/your/ds-repo/compose/.apps` you should be able to see it in the GUI and `ds -a <your new app>`

## Adding an App

So you want to add a new app to DockSTARTer? It's pretty easy if you have a working docker compose.

1. (Suggested) Develop a functional docker container for your new app in docker-compose.override.yml. Running `ds -c` should succesfully launch your new docker container and you'll be able to test this container to determine what properties should be specified in your docker compose file.
1. Add a new folder in `/path/to/your/ds-repo/compose/.apps` for your new app.
1. Populate the newly created folder above with .yml files. Read through the [YAML files](#YAML-files) section to understand which files to create and how to decompose the container you defined in step 1 above into the various .yml files needed.
1. Test your app .yml files as suggested in the [Testing](#Testing) section. _Note: if you created the docker container (as suggested by step 1) in docker-compose.override.yml you should comment out or delete those lines before testing_
1. Write app specific documentation in `/path/to/your/ds-repo/docs/apps/<appname>.md`
1. Create a navigation link in mkdocs for this new documentation written in the step above. Edit the file `/path/to/your/ds-repo/mkdocs.yml`

Look at the **App Specifics** list in the **nav** section and add a new line for your app `- apps/<appname>.md`

### Testing

- Try adding and removing using the CLI. `ds -a <appname>` and `ds -r <appname>`
- `ds -c` should succesfully start your new app container. Test the DockSTARTer created container for app specific functionality
- Try adding and removing from the GUI. (`ds` to launch the GUI)

## Shell scripts

- Remeber [Shell Scripts Matter](https://dev.to/thiht/shell-scripts-matter)
- [Use the Unofficial Bash Strict Mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/)
- Follow the [Shell Style Guide](https://google.github.io/styleguide/shell.xml)
- Use [Defensive BASH Programming](https://web.archive.org/web/20180917174959/http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/)
- Should be validated using the following tools (recommended to be installed locally):
  - [shellcheck](https://github.com/koalaman/shellcheck)
  - [shfmt](https://github.com/mvdan/sh)

## YAML files

- Should be formatted with [https://prettier.io/](https://prettier.io/)
- Should be sorted alphabetically
- Are separated into multiple files:
  - `<appname>.yml` is the main YAML template for an app and should have elements in the following order:
    - `container_name` should match `<appname>`
    - `environment` should contain the environment variables used by the app
      - `- TZ=${TZ}` is always included even if not needed unless some other form of timezone variable is used
    - `labels` should contain the labels used by the app. `appvars` should be lowercase in the labels file and are converted to uppercase automatically to become variables in `.env`. The values in the labels file become the default values in `.env`
      - `com.dockstarter.appinfo.deprecated: "<true|false>"` indicates if an app is deprecated
      - `com.dockstarter.appinfo.description: "<Description>"` will show the description in the menus
      - `com.dockstarter.appinfo.nicename: "<AppName>"` must match `<appname>` exactly but can have mixed case. Ex: Portainer vs PORTAINER
      - `com.dockstarter.appvars.<appname>_enabled: "false"` must be included and default to false. Users pick which apps are enabled
      - `com.dockstarter.appvars.<appname>_network_mode: ""` must be included and default to blank.
      - `com.dockstarter.appvars.<appname>_<var_name>: "<var_value>"` one entry for each variable specific to the app environment. See existing apps for examples
    - `logging` and the items beneath it should be included exactly as shown in other apps
    - `restart` should be `unless-stopped` or should include a comment about why another option is used
    - `volumes` should contain the volumes used by the app
      - `- /etc/localtime:/etc/localtime:ro` is always included
      - `- ${DOCKERCONFDIR}/<appname>:<container_config>` should be used to define the primary config directory for the app
      - `- ${DOCKERSTORAGEDIR}:/storage` is always included
  - `<appname>.hostname.yml` sets the hostname to use the `${DOCKERHOSTNAME}` variable
  - `<appname>.netmode.yml` contains the `<APPNAME>_NETWORK_MODE` variable
  - `<appname>.ports.yml` contains the ports used by the app. This file can be excluded if the app does not require ports
  - At least one of the following files must be included:
    - `<appname>.aarch64.yml` defines the aarch64 or arm64 image
    - `<appname>.armv7l.yml` defines the armv7l or armhf image
    - `<appname>.x86_64.yml` defines the x86_64 image

## .env.example file

- Contains environment variables to be used in the YAML templates
- All variables should be UPPERCASE
- Variables are split into sections with a comment to indicate the section name.
- Sections should be in the following order
  - `# Global Settings`
  - `# VPN Settings`
  - `# END OF DEFAULT SETTINGS` should be the last non-blank line in the file and followed by a blank line. Variables for apps enabled by DS will be placed alphabetically beneath this like. Users may also define their own variables after this point in their .env file

## Markdown files

- Should be checked with [markdownlint](https://github.com/markdownlint/markdownlint)
  - [Rules](https://github.com/markdownlint/markdownlint/blob/master/docs/RULES.md#rules) MD013, MD033, and MD034 are exempted from linting. E.g. running from the CLI `mdl -r ~MD013,~MD033,~MD034 <.md file path>`
