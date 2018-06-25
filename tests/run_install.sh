#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_install() {
    bash "${SCRIPTPATH}/main.sh" -xi

    yq --version || exit 1
    docker run hello-world || exit 1
    docker-compose --version || exit 1
}
