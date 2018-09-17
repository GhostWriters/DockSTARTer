# [DockSTARTer](https://ghostwriters.github.io/DockSTARTer/) [![Gitter](https://img.shields.io/gitter/room/GhostWriters/DockSTARTer.svg?logo=gitter-white)](https://gitter.im/GhostWriters/DockSTARTer) [![Discord](https://img.shields.io/discord/477959324183035936.svg?logo=discord)](https://discord.gg/YFyJpmH) [![Travis (.com) branch](https://img.shields.io/travis/com/GhostWriters/DockSTARTer/master.svg?logo=travis)](https://travis-ci.com/GhostWriters/DockSTARTer) <!--[![Codacy grade](https://img.shields.io/codacy/grade/8b0d850b18a64b3fa3c7514ca33855f3/master.svg)](https://www.codacy.com/app/GhostWriters/DockSTARTer)--> [![GitHub](https://img.shields.io/github/license/GhostWriters/DockSTARTer.svg)](https://github.com/GhostWriters/DockSTARTer/blob/master/LICENSE.md)

The main goal of DockSTARTer is to make it quick and easy to get up and running with Docker.

You may choose to rely on DockSTARTer for various changes to your Docker system, or use DockSTARTer as a stepping stone and learn to do more advanced configurations.

![Main Menu](https://i.imgur.com/eFUnl9o.png)
![App Selection](https://i.imgur.com/iNIRPPc.png)
![Value Prompt](https://i.imgur.com/XrrYJ4r.png)

## Getting Started

### One Time Setup (required)
##### Update your system
- APT Systems (Debian/Ubuntu/Raspbian/etc)
```
sudo apt-get update
sudo apt-get install curl git grep sed whiptail
sudo apt-get dist-upgrade
```
- DNF Systems (Fedora)
```
sudo dnf install curl git grep newt sed
sudo dnf upgrade --refresh
```
- YUM Systems (CentOS)
```
sudo yum install curl git grep newt sed
sudo yum upgrade
```
##### Reboot your system
```
sudo reboot
```
After rebooting, clone the repo
```
git clone https://github.com/GhostWriters/DockSTARTer ~/.docker
```

### Running DockSTARTer
```
sudo bash ~/.docker/main.sh
```
You should now see the main menu from the screenshot above. On your first run you should choose is `Install Dependencies`. At the end of this you will be prompted to reboot (required). After the reboot run DockSTARTer again using the same command above and select `Configure Applications`. You will be guided through selecting apps and starting the app containers.

See our [Wiki](https://github.com/GhostWriters/DockSTARTer/wiki/) for more detailed information.

## Feature Requests

We have switched to using GitHub for [Feature Requests](https://github.com/GhostWriters/DockSTARTer/issues/new?template=feature_request.md). Click the link and fill out the information to request a feature.

FeatHub will no longer be checked or maintained.

## Special Thanks

-   [SmartHomeBeginner.com](https://www.smarthomebeginner.com/) for creating [AtoMiC-ToolKit](https://github.com/htpcBeginner/AtoMiC-ToolKit) that served as this project's primary inspiration, and later [this](https://www.smarthomebeginner.com/docker-home-media-server-2018-basic/) guide that provided some initial direction with Docker.
-   [LinuxServer.io](https://www.linuxserver.io/) for maintaining the majority of the Docker images used in this project.

## Supporters [![Beerpay](https://img.shields.io/beerpay/GhostWriters/DockSTARTer.svg)](https://beerpay.io/GhostWriters/DockSTARTer) / Contributors [![GitHub contributors](https://img.shields.io/github/contributors/GhostWriters/DockSTARTer.svg)](https://GitHub.com/GhostWriters/DockSTARTer/graphs/contributors/)

This project is primarily maintained by [nemchik](https://github.com/GhostWriters/DockSTARTer/commits?author=nemchik) and [TommyE123](https://github.com/GhostWriters/DockSTARTer/commits?author=TommyE123)
