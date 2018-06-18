#!/bin/bash

install_yq () {
    # # https://github.com/mikefarah/yq
    local AVAILABLE_YQ
    AVAILABLE_YQ=$(curl -H "${GH_HEADER}" -s "https://api.github.com/repos/mikefarah/yq/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    if [[ ${ARCH} == "arm64" ]] || [[ ${ARCH} == "armhf" ]]; then
        curl -H "${GH_HEADER}" -L "https://github.com/mikefarah/yq/releases/download/${AVAILABLE_YQ}/yq_linux_arm" -o /usr/local/bin/yq
    fi
    if [[ ${ARCH} == "amd64" ]]; then
        curl -H "${GH_HEADER}" -L "https://github.com/mikefarah/yq/releases/download/${AVAILABLE_YQ}/yq_linux_amd64" -o /usr/local/bin/yq
    fi
    chmod +x /usr/local/bin/yq
}
