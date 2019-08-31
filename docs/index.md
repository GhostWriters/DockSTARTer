# <!-- Home -->

[![DockSTARTer](https://github.com/GhostWriters/DockSTARTer/raw/master/.github/logo.png)](https://dockstarter.com)

[![Supporters on Open Collective](https://img.shields.io/opencollective/all/DockSTARTer.svg?style=flat-square&color=607D8B)](#supporters)
[![Discord chat](https://img.shields.io/discord/477959324183035936.svg?style=flat-square&color=607D8B&logo=discord)](https://discord.gg/YFyJpmH)
[![GitHub contributors](https://img.shields.io/github/contributors/GhostWriters/DockSTARTer.svg?style=flat-square&color=607D8B)](https://github.com/GhostWriters/DockSTARTer/graphs/contributors)
[![GitHub last commit master](https://img.shields.io/github/last-commit/GhostWriters/DockSTARTer/master.svg?style=flat-square&color=607D8B&label=code%20committed)](https://github.com/GhostWriters/DockSTARTer/commits/master)
[![GitHub last commit docs](https://img.shields.io/github/last-commit/GhostWriters/DockSTARTer.com/master.svg?style=flat-square&color=607D8B&label=docs%20committed)](https://github.com/GhostWriters/DockSTARTer.com/commits/master)
[![GitHub license](https://img.shields.io/github/license/GhostWriters/DockSTARTer.svg?style=flat-square&color=607D8B)](https://github.com/GhostWriters/DockSTARTer/blob/master/LICENSE.md)
[![Travis (.com) branch](https://img.shields.io/travis/com/GhostWriters/DockSTARTer/master.svg?style=flat-square&color=607D8B&logo=travis)](https://travis-ci.com/GhostWriters/DockSTARTer)

The main goal of DockSTARTer is to make it quick and easy to get up and running with Docker.

You may choose to rely on DockSTARTer for various changes to your Docker system, or use DockSTARTer as a stepping stone and learn to do more advanced configurations.

![Main Menu](https://i.imgur.com/odfRk0j.png)

![App Select](https://i.imgur.com/tFsu2Hh.png)

![Value Prompt](https://i.imgur.com/k1bdAoQ.png)

![Command Line Interface](https://i.imgur.com/Y8F3uT2.png)

## Getting Started

### System Requirements

- You must be running a [Supported platform](https://docs.docker.com/install/#supported-platforms) or an operating system based on a supported platform. Platforms named below will link to documentation listing compatible versions.
- You must be logged in as a non-root user with sudo permissions.

### One Time Setup (required)

- APT Systems ([Debian](https://docs.docker.com/install/linux/docker-ce/debian/#os-requirements), [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/#os-requirements), etc)

```bash
sudo apt-get install curl git
bash -c "$(curl -fsSL https://get.dockstarter.com)"
sudo reboot
```

> Raspbian requires a few extra commands

```bash
sudo apt-get update
sudo apt-get dist-upgrade
sudo apt-get install curl git
bash -c "$(curl -fsSL https://get.docker.com)"
bash -c "$(curl -fsSL https://get.dockstarter.com)"
sudo reboot
```

- DNF Systems ([Fedora](https://docs.docker.com/install/linux/docker-ce/fedora/#os-requirements))

```bash
sudo dnf install curl git
bash -c "$(curl -fsSL https://get.dockstarter.com)"
sudo reboot
```

- YUM Systems ([CentOS](https://docs.docker.com/install/linux/docker-ce/centos/#os-requirements))

```bash
sudo yum install curl git
bash -c "$(curl -fsSL https://get.dockstarter.com)"
sudo reboot
```

<details>
  <summary>Alternate install (any system)</summary>

The standard install above downloads the initial script using a method with some known risks. For those concerned with the security of the above method here is an alternative:

```bash
## NOTE: Run the appropriate command for your distro
sudo apt-get install curl git
sudo dnf install curl git
sudo yum install curl git

## NOTE: Do not sudo the next line.
git clone https://github.com/GhostWriters/DockSTARTer "/home/${USER}/.docker"
sudo bash /home/${USER}/.docker/main.sh -i
sudo reboot
```

</details>

### Running DockSTARTer

```bash
sudo ds
```

To run DockSTARTer use the command above. You should now see the main menu from the screenshots. Select `Configuration` and then `Full Setup` and you will be guided through selecting apps and starting containers.

See our [documentation](https://dockstarter.com/introduction/) for more detailed information.

## Support

[![Discord chat](https://img.shields.io/discord/477959324183035936.svg?style=flat-square&color=607D8B&logo=discord)](https://discord.gg/YFyJpmH)

Click the chat badge to join us on Discord for support!

[[Feature Request](https://github.com/GhostWriters/DockSTARTer/issues/new?template=feature_request.md)] [[Bug Report](https://github.com/GhostWriters/DockSTARTer/issues/new?template=bug_report.md)]

## Contributors

[![GitHub contributors](https://img.shields.io/github/contributors/GhostWriters/DockSTARTer.svg?style=flat-square&color=607D8B)](https://github.com/GhostWriters/DockSTARTer/graphs/contributors)

This project exists thanks to all the people who contribute.
[![GitHub contributors](https://opencollective.com/DockSTARTer/contributors.svg?button=false)](https://GitHub.com/GhostWriters/DockSTARTer/graphs/contributors)

## Supporters

Support the project by donating on Open Collective.

### Backers

[![Backers on Open Collective](https://img.shields.io/opencollective/tier/DockSTARTer/7408.svg?style=flat-square&color=607D8B&label=backers)](https://opencollective.com/DockSTARTer#backer)

Thank you to all our backers! [[Become a backer](https://opencollective.com/DockSTARTer#backer)]

[![Backers on Open Collective](https://opencollective.com/DockSTARTer/tiers/backer.svg)](https://opencollective.com/DockSTARTer#backers)

### Sponsors

[![Sponsors on Open Collective](https://img.shields.io/opencollective/tier/DockSTARTer/7409.svg?style=flat-square&color=607D8B&label=sponsors)](https://opencollective.com/DockSTARTer#sponsor)

Support this project by becoming a sponsor. Your logo will show up here with a link to your website. [[Become a sponsor](https://opencollective.com/DockSTARTer#sponsor)]

[![Sponsors on Open Collective](https://opencollective.com/DockSTARTer/tiers/sponsor/0/avatar.svg)](https://opencollective.com/DockSTARTer/tiers/sponsor/0/website) [![Sponsors on Open Collective](https://opencollective.com/DockSTARTer/tiers/sponsor/1/avatar.svg)](https://opencollective.com/DockSTARTer/tiers/sponsor/1/website) [![Sponsors on Open Collective](https://opencollective.com/DockSTARTer/tiers/sponsor/2/avatar.svg)](https://opencollective.com/DockSTARTer/tiers/sponsor/2/website) [![Sponsors on Open Collective](https://opencollective.com/DockSTARTer/tiers/sponsor/3/avatar.svg)](https://opencollective.com/DockSTARTer/tiers/sponsor/3/website) [![Sponsors on Open Collective](https://opencollective.com/DockSTARTer/tiers/sponsor/4/avatar.svg)](https://opencollective.com/DockSTARTer/tiers/sponsor/4/website) [![Sponsors on Open Collective](https://opencollective.com/DockSTARTer/tiers/sponsor/5/avatar.svg)](https://opencollective.com/DockSTARTer/tiers/sponsor/5/website) [![Sponsors on Open Collective](https://opencollective.com/DockSTARTer/tiers/sponsor/6/avatar.svg)](https://opencollective.com/DockSTARTer/tiers/sponsor/6/website) [![Sponsors on Open Collective](https://opencollective.com/DockSTARTer/tiers/sponsor/7/avatar.svg)](https://opencollective.com/DockSTARTer/tiers/sponsor/7/website) [![Sponsors on Open Collective](https://opencollective.com/DockSTARTer/tiers/sponsor/8/avatar.svg)](https://opencollective.com/DockSTARTer/tiers/sponsor/8/website) [![Sponsors on Open Collective](https://opencollective.com/DockSTARTer/tiers/sponsor/9/avatar.svg)](https://opencollective.com/DockSTARTer/tiers/sponsor/9/website)

## Special Thanks

- [SmartHomeBeginner.com](https://www.smarthomebeginner.com) for creating [AtoMiC-ToolKit](https://github.com/htpcBeginner/AtoMiC-ToolKit) that served as this project's primary inspiration, and later [this](https://www.smarthomebeginner.com/docker-home-media-server-2018-basic/) guide that provided some initial direction with Docker.
- [LinuxServer.io](https://www.linuxserver.io) for maintaining the majority of the Docker images used in this project.
