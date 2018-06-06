#!/bin/bash
# Script Name: Bashate validation

find . -name '*.sh' -print0 | xargs -0 bashate -i E006
