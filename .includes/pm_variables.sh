#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -argx PM_COMMAND_DEPS=(
    "column"
    "curl"
    "dialog"
    "envsubst"
    "git"
    "grep"
    "sed"
)

declare -argx PM_PACKAGE_BLACKLIST=(
    "9base"
    "busybox-grep"
    "busybox-sed"
    "curl-minimal"
    "gitlab-shell"
)
