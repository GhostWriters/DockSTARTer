#!/bin/bash

setup_docker_group () {
    # # https://docs.docker.com/install/linux/linux-postinstall/
    groupadd docker
    usermod -aG docker "${USER}"
}
