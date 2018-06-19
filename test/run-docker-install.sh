#!/bin/bash

SCRIPTPATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"

sh "${SCRIPTPATH}/docker-install.sh"

yq --version || exit 1
docker run hello-world || exit 1
docker-compose --version || exit 1
