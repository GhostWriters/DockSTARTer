#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ui_config_vpn() {
    run_script 'menu_value_prompt' LAN_NETWORK || return 1
    run_script 'menu_value_prompt' NS1 || return 1
    run_script 'menu_value_prompt' NS2 || return 1
    run_script 'menu_value_prompt' VPN_ENABLE || return 1
    run_script 'menu_value_prompt' VPN_OPTIONS || return 1
    run_script 'menu_value_prompt' VPN_PASS || return 1
    run_script 'menu_value_prompt' VPN_PROV || return 1
    run_script 'menu_value_prompt' VPN_USER || return 1
}
