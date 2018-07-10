#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

validate_bashate() {
    find . -name '*.sh' -print0 | xargs -0 bashate -i E006 || fatal "Bashate validation failure."
}
