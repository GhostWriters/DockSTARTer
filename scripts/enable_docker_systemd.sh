#!/bin/bash

enable_docker_systemd() {
    # # https://docs.docker.com/install/linux/linux-postinstall/
    [[ ${ISSYSTEMD} == true ]] && systemctl enable docker
}
