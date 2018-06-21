#!/bin/bash

install_machine_completion() {
    # # https://docs.docker.com/machine/completion/
    local AVAILABLE_MACHINE_COMPLETION
    AVAILABLE_MACHINE_COMPLETION=$(curl -H "${GH_HEADER}" -s "https://api.github.com/repos/docker/machine/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    curl -H "${GH_HEADER}" -L "https://raw.githubusercontent.com/docker/machine/${AVAILABLE_MACHINE_COMPLETION}/contrib/completion/bash/docker-machine.bash" -o /etc/bash_completion.d/docker-machine
}
