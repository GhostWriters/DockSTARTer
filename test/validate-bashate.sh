#!/bin/bash

find . -name '*.sh' -print0 | xargs -0 bashate -i E006
