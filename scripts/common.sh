#!/bin/bash

# # Colors
readonly CYAN='\e[34m'
readonly GREEN='\e[32m'
readonly RED='\e[31m'
readonly YELLOW='\e[33m'
readonly ENDCOLOR='\033[0m'

# # Check Arch
readonly ARCH=$(dpkg --print-architecture)

# # Check Systemd
if [[ -L "/sbin/init" ]]; then
    readonly ISSYSTEMD=true
else
    readonly ISSYSTEMD=false
fi

# # Github Token for Travis CI
if [[ ${CI} == true ]] && [[ ${TRAVIS} == true ]]; then
    readonly GH_HEADER="Authorization: token ${GH_TOKEN}"
fi

# # Runner Function
run_script () {
    source "${SCRIPTPATH}/scripts/${1}.sh"
    ${1};
}
