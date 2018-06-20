#!/bin/bash

run_install() {
    bash "${SCRIPTPATH}/main.sh -i"

    yq --version || return 1
    docker run hello-world || return 1
    docker-compose --version || return 1
}
