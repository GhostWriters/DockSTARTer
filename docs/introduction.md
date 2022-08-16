# Introduction

## What TrunkSTARTer Is

- TrunkSTARTer is a script that installs Docker and other dependencies for you.
- TrunkSTARTer comes with configurations to run various apps.
- TrunkSTARTer can be operated through a friendly GUI of terminal menus.
- TrunkSTARTer can be operated through commands for more advanced users who do not prefer the GUI.
- TrunkSTARTer is here to give you the freedom to choose what you want to run.
- TrunkSTARTer allows you to run apps that are not included using [Overrides / Introduction](https://trunkstarter.com/overrides/introduction).

## What TrunkSTARTer Is Not

- TrunkSTARTer is not a pre-made set of apps that run an exact way (you get to choose what to run and how to run it).
- TrunkSTARTer does not configure apps for you (think of it more like installing apps as a service, settings inside the app are still up to you, although our documentation will have recommendations).
- TrunkSTARTer does not configure storage for you (you may use local storage, or cloud storage, multiple disks, raid, etc).

## System Requirements

### Supported Operating Systems

You must be running a [Supported Platform](https://docs.docker.com/install/#supported-platforms) or an operating system based on a supported platform. Platforms named below will link to documentation listing compatible versions.

- [CentOS](https://docs.docker.com/install/linux/docker-ce/centos/#os-requirements)
- [Debian](https://docs.docker.com/install/linux/docker-ce/debian/#os-requirements)
- [Fedora](https://docs.docker.com/install/linux/docker-ce/fedora/#os-requirements)
- [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/#os-requirements)

Any operating system based on one of the above (ex: Raspbian) should also work as long as you can install the [officially supported script](https://get.docker.com/). TrunkSTARTer will attempt to perform this install for you if possible.

### Supported Hardware

Any `x86_64`, `armv7l`, or `aarch64` system should be able to run one of the supported operating systems listed above. ARM CPUs may have a limited selection of supported containers.

### Windows Support

Currently we recommend installing one of the supported platforms above in a VM. In the future we may be able to support the Windows Subsystem for Linux version 2.

