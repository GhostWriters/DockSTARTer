#!/bin/bash

readonly SCRIPTPATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
source "${SCRIPTPATH}/scripts/common.sh"

run_script 'generate_yml';
run_script 'run_compose';
