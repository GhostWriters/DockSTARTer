# [![DockSTARTer](https://github.com/GhostWriters/DockSTARTer/raw/master/.github/logo.png)](https://dockstarter.com/)

[![Discord](https://img.shields.io/discord/477959324183035936.svg?logo=discord)](https://discord.gg/YFyJpmH) [![Travis (.com) branch](https://img.shields.io/travis/com/GhostWriters/DockSTARTer/master.svg?logo=travis)](https://travis-ci.com/GhostWriters/DockSTARTer) [![GitHub](https://img.shields.io/github/license/GhostWriters/DockSTARTer.svg)](https://github.com/GhostWriters/DockSTARTer/blob/master/LICENSE.md)

The main goal of DockSTARTer is to make it quick and easy to get up and running with Docker.

You may choose to rely on DockSTARTer for various changes to your Docker system, or use DockSTARTer as a stepping stone and learn to do more advanced configurations.

![Main Menu](https://i.imgur.com/odfRk0j.png)

![App Select](https://i.imgur.com/tFsu2Hh.png)

![Value Prompt](https://i.imgur.com/k1bdAoQ.png)

## Getting Started

### One Time Setup (required)

- APT Systems (Debian/Ubuntu/Raspbian/etc)

```bash
sudo apt-get install curl git
bash -c "$(curl -fsSL https://get.dockstarter.com)"
sudo reboot
```

- DNF Systems (Fedora)

```bash
sudo dnf install curl git
bash -c "$(curl -fsSL https://get.dockstarter.com)"
sudo reboot
```

- YUM Systems (CentOS)

```bash
sudo yum install curl git
bash -c "$(curl -fsSL https://get.dockstarter.com)"
sudo reboot
```

### Running DockSTARTer

```bash
sudo ds
```

To run DockSTARTer use the command above. You should now see the main menu from the screenshots. Select `Configuration` and then `Full Setup` and you will be guided through selecting apps and starting containers.

See our [Wiki](https://github.com/GhostWriters/DockSTARTer/wiki/) for more detailed information.

## Feature Requests

We have switched to using GitHub for [Feature Requests](https://github.com/GhostWriters/DockSTARTer/issues/new?template=feature_request.md). Click the link and fill out the information to request a feature.

FeatHub will no longer be checked or maintained.

## Special Thanks

- [SmartHomeBeginner.com](https://www.smarthomebeginner.com/) for creating [AtoMiC-ToolKit](https://github.com/htpcBeginner/AtoMiC-ToolKit) that served as this project's primary inspiration, and later [this](https://www.smarthomebeginner.com/docker-home-media-server-2018-basic/) guide that provided some initial direction with Docker.
- [LinuxServer.io](https://www.linuxserver.io/) for maintaining the majority of the Docker images used in this project.

## Supporters [![Beerpay](https://img.shields.io/beerpay/GhostWriters/DockSTARTer.svg)](https://beerpay.io/GhostWriters/DockSTARTer) / Contributors [![GitHub contributors](https://img.shields.io/github/contributors/GhostWriters/DockSTARTer.svg)](https://GitHub.com/GhostWriters/DockSTARTer/graphs/contributors/)

This project is primarily maintained by [nemchik](https://github.com/GhostWriters/DockSTARTer/commits?author=nemchik) and [TommyE123](https://github.com/GhostWriters/DockSTARTer/commits?author=TommyE123)
