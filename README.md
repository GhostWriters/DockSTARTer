# <!-- Home -->

[![TrunkStarter]()](https://trunkstarter.com)

[![Discord chat](https://img.shields.io/discord/477959324183035936.svg?style=flat-square&color=607D8B&logo=discord)](https://discord.gg/trunk-recorder)


The main goal of TrunkSTARTer is to make it quick and easy to get up and running with SDR apps on Docker.

You may choose to rely on TrunkSTARTer for various changes to your Docker system or use TrunkSTARTer as a stepping stone and learn to do more advanced configurations.


## Getting Started

### System Requirements

- You must be running a [supported platform](https://docs.docker.com/install/#supported-platforms) or an operating system based on a supported platform. Platforms named below will link to documentation listing compatible versions.
- You must be logged in as a non-root user with sudo permissions.

### One Time Setup (required)

- APT Systems ([Debian](https://docs.docker.com/install/linux/docker-ce/debian/#os-requirements), [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/#os-requirements), etc)

  ```bash
  sudo apt-get install curl git
  bash -c "$(curl -fsSL )"
  sudo reboot
  ```

  > Raspbian requires a few extra commands

  ```bash
  sudo apt-get update
  sudo apt-get dist-upgrade
  sudo apt-get install curl git
  bash -c "$(curl -fsSL https://get.docker.com)"
  bash -c "$(curl -fsSL )"
  sudo reboot
  ```

  > OpenMediaVault (OMV) requires [special instructions found here](https://trunkstarter.com/advanced/openmediavault/)

- DNF Systems ([Fedora](https://docs.docker.com/install/linux/docker-ce/fedora/#os-requirements))

  ```bash
  sudo dnf install curl git
  bash -c "$(curl -fsSL )"
  sudo reboot
  ```

- Pacman Systems (Arch, Manjaro, EndeavourOS, etc.)

  ```bash
  sudo pacman -Sy curl docker git
  bash -c "$(curl -fsSL )"
  sudo reboot
  ```

- YUM Systems ([CentOS](https://docs.docker.com/install/linux/docker-ce/centos/#os-requirements))

  ```bash
  sudo yum install curl git
  bash -c "$(curl -fsSL )"
  sudo reboot
  ```

<details>
  <summary>Alternate install (any system)</summary>

The standard install above downloads the initial script using a method with some known risks. For those concerned with the security of the above method, here is an alternative:

```bash
## NOTE: Run the appropriate command for your distro
sudo apt-get install curl git
sudo dnf install curl git
sudo pacman -Sy curl git
sudo yum install curl git
```

Then

```bash
git clone https://github.com/jodfie/TrunkSTARTer "/home/${USER}/.docker"
sudo bash /home/"${USER}"/.docker/main.sh -vi
sudo reboot
```

</details>

### Running TrunkSTARTer

```bash
ts
```

To run TrunkSTARTer, use the command above. You should now see the main menu from the screenshots. Select `Configuration` and then `Full Setup`, and you will be guided through selecting apps and starting containers.

See our [documentation](https://trunkstarter.com/introduction/) for more detailed information.

## Support

[![Discord chat](https://img.shields.io/discord/477959324183035936.svg?style=flat-square&color=607D8B&logo=discord)](https://discord.gg/trunk-recorder)

Click the chat badge to join us on Discord for support!

[Feature Request](https://github.com/jodfie/TrunkSTARTer/issues/new?template=feature_request.md) | [Bug Report](https://github.com/jodfie/TrunkSTARTer/issues/new?template=bug_report.md)

Additional information can be found on our [Support Page](https://trunkstarter.com/basics/support/).

## Contributing

Want to help develop DockSTARTer? Check out our [contributing guidelines](https://github.com/jodfie/TrunkSTARTer/blob/master/.github/CONTRIBUTING.md) and [code of conduct](https://github.com/jodfie/TrunkSTARTer/blob/master/.github/CODE_OF_CONDUCT.md).

### Contributors

## Supporters

Support the project by donating on [Open Collective]().

### Backers

[![Backers on Open Collective](https://img.shields.io/opencollective/tier/DockSTARTer/7408.svg?style=flat-square&color=607D8B&label=backers)]()

Thank you to all our backers! [Become a backer]().

[![Backers on Open Collective]()]()

### Sponsors

[![Sponsors on Open Collective]()]()

Support this project by becoming a sponsor. Your logo will show up here with a link to your website. [Become a sponsor]().

## Special Thanks

- [nemchik (iXNyne)](https://github.com/nemchik) for creating [DockSTARter](https://github.com/Ghostwriters/Dockstarter) that served as this project's primary codebase and nemchik and the rest of the DS staffs support in my constant bothering with questions.
- [LinuxServer.io](https://www.linuxserver.io) for maintaining some of the Docker images used in this project.
