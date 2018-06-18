#!/bin/bash

readonly SCRIPTPATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
source "${SCRIPTPATH}/scripts/common.sh"

source "${SCRIPTPATH}/docker-install.sh"

yq --version || exit 1
docker run hello-world || exit 1
docker-compose --version || exit 1
