#!/bin/bash
# Script Name: Bashate check

find . -name '*.sh' -print0 | xargs -0 bashate -i E006
