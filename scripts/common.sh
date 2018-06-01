#!/bin/bash
# Script Name: Common variables

# # Colors
CYAN='\e[34m'
GREEN='\e[32m'
RED='\e[31m'
YELLOW='\e[33m'
ENDCOLOR='\033[0m'

# # Arch check
ARCH=""
case $(uname -m) in
  x86_64) ARCH="amd64" ;;
  arm)    dpkg --print-architecture | grep -q "arm64" && ARCH="arm64" || ARCH="arm" ;;
esac
