#!/bin/bash

root_check () {
    if [[ $EUID -ne 0 ]] ; then
        echo
        echo -e "${RED}Please run as root using the command: ${ENDCOLOR}sudo bash $1"
        echo
        exit 0
    fi
}
