# Introduction

## What DockSTARTer Is

- DockSTARTer is a script that installs Docker, Compose, and other dependencies for you.
- DockSTARTer comes with configurations to run various apps.
- DockSTARTer can be operated through a friendly GUI of terminal menus.
- DockSTARTer can be operated through commands for more advanced users who do not prefer the GUI.
- DockSTARTer is here to give you the freedom to choose what you want to run.
- DockSTARTer allows you to run apps that are not included using [Overrides](https://dockstarter.com/advanced/overrides/).

## What DockSTARTer Is Not

- DockSTARTer is not a premade set of apps that run an exact way (you get to choose what to run and how to run it).
- DockSTARTer does not configure apps for you (think of it more like installing apps as a service, settings inside the app are still up to you, although our documentation will have recommendations).
- DockSTARTer does not configure storage for you (you may use local storage, or cloud storage, multiple disks, raid, etc).

## System Requirements

### Supported Operating Systems

You must be running a [Supported platform](https://docs.docker.com/install/#supported-platforms) or an operating system based on a supported platform. Platforms named below will link to documentation listing compatible versions.

- [CentOS](https://docs.docker.com/install/linux/docker-ce/centos/#os-requirements)
- [Debian](https://docs.docker.com/install/linux/docker-ce/debian/#os-requirements)
- [Fedora](https://docs.docker.com/install/linux/docker-ce/fedora/#os-requirements)
- [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/#os-requirements)

Any operating system based on one of the above (ex: Raspbian) should also work as long as you can install the officially supported [https://get.docker.com/](https://get.docker.com/) script. DockSTARTer will attempt to perform this install for you if possible.

### Supported Hardware

Any `x86_64`, `armv7l`, or `aarch64` system should be able to run one of the supported operating systems listed above. ARM CPUs may have a limited selection of supported containers.

### Windows Support

Currently we recommend installing one of the supported platforms above in a VM. In the future we may be able to support the Windows Subsystem for Linux version 2.

## Videos

- [Getting Started](https://www.youtube.com/watch?v=6pkbS07CAnU)
- [Version Control Visualization](https://www.youtube.com/watch?v=7Y9q86H1biE)
