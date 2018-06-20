#!/bin/bash

validate_bashate() {
    find . -name '*.sh' -print0 | xargs -0 bashate -i E006 || return 1
}
