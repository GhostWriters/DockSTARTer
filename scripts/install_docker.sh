#!/bin/bash

install_docker() {
    # # https://github.com/docker/docker-install
    curl -fsSL get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
}
