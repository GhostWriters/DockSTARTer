#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

validate_bashate() {
    apt-get -y install python-pip > /dev/null 2>&1
    pip install -U bashate > /dev/null 2>&1

    find . -name '*.sh' -print0 | xargs -0 bashate -i E006 || fatal "Bashate validation failure."
}
