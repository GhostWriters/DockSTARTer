#!/bin/bash

root_check () {
    if [[ $EUID -ne 0 ]] ; then
        echo
        echo -e "${RED}Please run as root using the command: ${ENDCOLOR}sudo bash ${SCRIPTNAME} ${ARGS}"
        echo
        exit 0
    fi
}
