#!/bin/bash

TESTPATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"

bash "${TESTPATH}/docker-install.sh"

yq --version || exit 1
docker run hello-world || exit 1
docker-compose --version || exit 1
