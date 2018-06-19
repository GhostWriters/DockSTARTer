#!/bin/bash

readonly SCRIPTNAME="$(basename "$0")"
readonly SCRIPTPATH="$(readlink -m "$(dirname "$0")")"
readonly ARGS="$*"
source "${SCRIPTPATH}/scripts/common.sh"

run_script 'generate_yml';
run_script 'run_compose';
