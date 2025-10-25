#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

usage() {
    local Option=${1-}
    local NoHeading=${2-}

    local Found=''
    case "${Option}" in
        *)
            if [[ -z ${NoHeading-} ]]; then
                local APPLICATION_HEADING="${C["Version"]-}${APPLICATION_NAME}${NC-}"
                if [[ ${APPLICATION_VERSION-} ]]; then
                    APPLICATION_HEADING+=" [${C["Version"]-}${APPLICATION_VERSION}${NC-}]"
                fi
                if ds_update_available; then
                    APPLICATION_HEADING+=" (${C["Update"]-}Update Available${NC-})"
                fi
                cat << EOF
Usage: ${C["UsageCommand"]-}${APPLICATION_COMMAND}${NC-} [${C["UsageCommand"]-}<Flags>${NC-}] [${C["UsageCommand"]-}<Command>${NC-}] ...
NOTE: The '${C["UsageCommand"]-}${APPLICATION_COMMAND}${NC-}' shortcut is only available after the first run of
    bash main.sh

${APPLICATION_HEADING}
This is the main ${APPLICATION_NAME} script.
For regular usage you can run without providing any options.

You may include multiple commands on the command-line, and they will be executed in
the order given, only stopping on an error. Any flags included only apply to the
following command, and get reset before the next command.

Any command that takes a variable name, the variable will by default be looked for
in the global '${C["UsageFile"]-}.env${NC-}' file. If the variable name used is in form of '${C["UsageVar"]-}app:var${NC-}', it
will instead refer to the variable '${C["UsageVar"]-}${C["UsageVar"]-}<var>${NC-}' in '${C["UsageFile"]-}.env.app.<app>${NC-}'.  Some commands
that take app names can use the form '${C["UsageApp"]-}app:${NC-}' to refer to the same file.

EOF
            fi
            ;;&
        "")
            if [[ -z ${NoHeading-} ]]; then
                cat << EOF

Flags:

EOF
            fi
            ;;&
        -f | --force | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-f --force${NC-}
    Force certain install/upgrade actions to run even if they would not be needed.
EOF
            ;;&
        -g | --gui | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-g --gui${NC-}
    Use dialog boxes
EOF
            ;;&
        -v | --verbose | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-v --verbose${NC-}
    Verbose
EOF
            ;;&
        -x | --debug | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-x --debug${NC-}
    Debug
EOF
            ;;&
        -y | --yes | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-y --yes${NC-}
    Assume Yes for all prompts
EOF
            ;;&
        "")
            if [[ -z ${NoHeading-} ]]; then
                cat << EOF

CLI Commands:

EOF
            fi
            ;;&
        -a | --add | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-a --add${NC-} ${C["UsageApp"]-}<app>${NC-} [${C["UsageApp"]-}<app>${NC-} ...]${NC-}
    Add the default variables for the app(s) specified
EOF
            ;;&
        -c | --compose | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-c --compose${NC-} < ${C["UsageOption"]-}pull${NC-} | ${C["UsageOption"]-}up${NC-} | ${C["UsageOption"]-}down${NC-} | ${C["UsageOption"]-}stop${NC-} | ${C["UsageOption"]-}restart${NC-} | ${C["UsageOption"]-}update${NC-} > [${C["UsageApp"]-}<app>${NC-} ...]${NC-}
    Run docker compose commands. If no command is given, it does an '${C["UsageOption"]-}update${NC-}'.
    The '${C["UsageOption"]-}update${NC-}' command is the same as a '${C["UsageOption"]-}pull${NC-}' followed by an '${C["UsageOption"]-}up${NC-}'
${C["UsageCommand"]-}-c --compose${NC-} < ${C["UsageOption"]-}generate${NC-} | ${C["UsageOption"]-}merge${NC-} >${NC-}
    Generates the '${C["UsageFile"]-}docker-compose.yml${NC-} file
EOF
            ;;&
        --config-pm | --config-pm-auto | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-T --config-pm${NC-} ${C["UsageOption"]-}<package manager>${NC-}
    Select the specified package manager to install dependencies
${C["UsageCommand"]-}-T --config-pm-auto${NC-}
    Autodetect the package manager
EOF
            ;;&
        --config-pm-list | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--config-pm-list${NC-}
    Lists the compatible package managers
EOF
            ;;&
        --config-pm-table | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--config-pm-table${NC-}
    Lists the compatible package managers in a table format
EOF
            ;;&
        --config-pm-existing-list | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--config-pm-existing-list${NC-}
    Lists the existing package managers
EOF
            ;;&
        --config-pm-existing-table | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--config-pm-existing-table${NC-}
    Lists the existing package managers in a table format
EOF
            ;;&
        -e | --env | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-e --env${NC-}
    Update your '${C["UsageFile"]-}.env${NC-}' files with new variables
EOF
            ;;&
        --env-appvars | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--env-appvars${NC-} ${C["UsageApp"]-}<app>${NC-} [${C["UsageApp"]-}<app>${NC-} ...]${NC-}
    List all variable names for the app(s) specified
EOF
            ;;&
        --env-appvars-lines | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--env-appvars-lines${NC-} ${C["UsageApp"]-}<app>${NC-} [${C["UsageApp"]-}<app>${NC-} ...]${NC-}
    List all variables and values for the app(s) specified
EOF
            ;;&
        --env-get | --env-get= | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--env-get${NC-} ${C["UsageVar"]-}<var>${NC-} [${C["UsageVar"]-}<var>${NC-} ...]${NC-}
${C["UsageCommand"]-}--env-get=${NC-}${C["UsageVar"]-}<var>${NC-}
    Get the value of a ${C["UsageVar"]-}<var>${NC-}iable (variable name is forced to UPPER CASE)
EOF
            ;;&
        --env-get-line | --env-get-line= | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--env-get-line${NC-} ${C["UsageVar"]-}<var>${NC-} [${C["UsageVar"]-}<var>${NC-} ...]${NC-}
${C["UsageCommand"]-}--env-get-line=${NC-}${C["UsageVar"]-}<var>${NC-}
    Get the line of a ${C["UsageVar"]-}<var>${NC-}iable (variable name is forced to UPPER CASE)
EOF
            ;;&
        --env-get-literal | --env-get-literal= | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--env-get-literal${NC-} ${C["UsageVar"]-}<var>${NC-} [${C["UsageVar"]-}<var>${NC-} ...]${NC-}
${C["UsageCommand"]-}--env-get-literal${NC-}=${C["UsageVar"]-}<var>${NC-}
    Get the literal value (including quotes) of a ${C["UsageVar"]-}<var>${NC-}iable (variable name is forced to UPPER CASE)
EOF
            ;;&
        --env-get-lower | --env-get-lower= | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--env-get-lower${NC-} ${C["UsageVar"]-}<var>${NC-} [${C["UsageVar"]-}<var>${NC-} ...]${NC-}
${C["UsageCommand"]-}--env-get-lower${NC-}=${C["UsageVar"]-}<var>${NC-}
    Get the value of a ${C["UsageVar"]-}<var>${NC-}iable
EOF
            ;;&
        --env-get-lower-line | --env-get-lower-line= | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--env-get-lower-line${NC-} ${C["UsageVar"]-}<var>${NC-} [${C["UsageVar"]-}<var>${NC-} ...]
${C["UsageCommand"]-}--env-get-lower-line=${NC-}${C["UsageVar"]-}<var>${NC-}
    Get the line of a ${C["UsageVar"]-}<var>${NC-}iable
EOF
            ;;&
        --env-get-lower-literal | --env-get-lower-literal= | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--env-get-lower-literal${NC-} ${C["UsageVar"]-}<var>${NC-} [${C["UsageVar"]-}<var>${NC-} ...]${NC-}
${C["UsageCommand"]-}--env-get-lower-literal=${NC-}${C["UsageVar"]-}<var>${NC-}
    Get the literal value (including quotes) of a ${C["UsageVar"]-}<var>${NC-}iable
EOF
            ;;&
        --env-set | --env-set= | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--env-set${NC-} ${C["UsageVar"]-}<var>=<val>${NC-}
${C["UsageCommand"]-}--env-set=${NC-}${C["UsageVar"]-}<var>,<val>${NC-}
    Set the ${C["UsageVar"]-}<val>${NC-}ue of a ${C["UsageVar"]-}<var>${NC-}iable (variable name is forced to UPPER CASE).
EOF
            ;;&
        --env-set-lower | --env-set-lower= | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--env-set-lower${NC-} ${C["UsageVar"]-}<var>=<val>${NC-}
${C["UsageCommand"]-}--env-set-lower=${NC-}${C["UsageVar"]-}<var>,<val>${NC-}
    Set the ${C["UsageVar"]-}<val>${NC-}ue of a ${C["UsageVar"]-}<var>${NC-}iable
EOF
            ;;&
        -l | --list) ;&
        --list-added) ;&
        --list-builtin) ;&
        --list-deprecated) ;&
        --list-enabled) ;&
        --list-disabled) ;&
        --list-nondeprecated) ;&
        --list-referenced) ;&
        "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-l --list${NC-}
    List all apps
${C["UsageCommand"]-}--list-added${NC-}
    List added apps
${C["UsageCommand"]-}--list-builtin${NC-}
    List builtin apps
${C["UsageCommand"]-}--list-deprecated${NC-}
    List deprecated apps
${C["UsageCommand"]-}--list-enabled${NC-}
    List enabled apps
${C["UsageCommand"]-}--list-disabled${NC-}
    List disabled apps
${C["UsageCommand"]-}--list-nondeprecated${NC-}
    List non-deprecated apps
${C["UsageCommand"]-}--list-referenced${NC-}
    List referenced apps (whether they are "built in" or not). An app is considered
    "referenced" if there is a variable matching the app's name in the global '${C["UsageFile"]-}.env${NC-}',
    there are any variables in the file '${C["UsageFile"]-}.env.app.<app>${NC-}', or the file '${C["UsageFile"]-}.env.app.<app>${NC-}'
    is referenced in '${C["UsageFile"]-}docker-compose.override.yml${NC-}'.
EOF
            ;;&
        -h | --help | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-h --help${NC-}
    Show this usage information
${C["UsageCommand"]-}-h --help${NC-} ${C["UsageOption"]-}<option>${NC-}
    Show the usage of the specified option
EOF
            ;;&
        -i | --install | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-i --install${NC-}
    Install/update all dependencies
EOF
            ;;&
        -p | --prune | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-p --prune${NC-}
    Remove unused docker resources
EOF
            ;;&
        -r | --remove | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-r --remove${NC-}
    Prompt to remove variables for all disabled apps
${C["UsageCommand"]-}-r --remove${NC-} ${C["UsageApp"]-}<app>${NC-} [${C["UsageApp"]-}<app>${NC-} ...]${NC-}
    Prompt to remove the variables for the app specified
EOF
            ;;&
        -R | --reset | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-R --reset${NC-}
    Resets ${APPLICATION_NAME} to always process environment files.
    This is usually not needed unless you have modified application templates yourself.
EOF
            ;;&
        -s | --status | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-s --status${NC-} ${C["UsageApp"]-}<app>${NC-} [${C["UsageApp"]-}<app>${NC-} ...]${NC-}
    Returns the enabled/disabled status for the app specified
EOF
            ;;&
        --status-disable) ;&
        --status-enable) ;&
        "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--status-disable${NC-} ${C["UsageApp"]-}<app>${NC-} [${C["UsageApp"]-}<app>${NC-} ...]${NC-}
    Disable the app specified
${C["UsageCommand"]-}--status-enable${NC-} ${C["UsageApp"]-}<app>${NC-} [${C["UsageApp"]-}<app>${NC-} ...]${NC-}
    Enable the app specified
EOF
            ;;&
        -t | --test | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-t --test${NC-} ${C["UsageFile"]-}<test_name>${NC-}
    Run tests to check the program
EOF
            ;;&
        -T | --theme | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-T --theme${NC-}
    Re-applies the current theme to the GUI
${C["UsageCommand"]-}-T --theme${NC-} ${C["UsageTheme"]-}<themename>${NC-}
    Applies the specified theme to the GUI
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-list | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--theme-list${NC-}
    Lists the available themes
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-table | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--theme-table${NC-}
    Lists the available themes in a table format
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-lines | --theme-no-lines | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--theme-lines${NC-}
${C["UsageCommand"]-}--theme-no-lines${NC-}
    Turn the line drawing characters on or off in the GUI
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-borders | --theme-no-borders | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--theme-borders${NC-}
${C["UsageCommand"]-}--theme-no-borders${NC-}
    Turn the borders on and off in the GUI
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-shadows | --theme-no-shadows | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--theme-shadows${NC-}
${C["UsageCommand"]-}--theme-no-shadows${NC-}
    Turn the shadows on or off in the GUI
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-scrollbar | --theme-no-scrollbar | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}--theme-scrollbar${NC-}
${C["UsageCommand"]-}--theme-no-scrollbar${NC-}
    Turn the scrollbar on or off in the GUI
EOF
            ;;&
        -u | --update | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-u --update${NC-}
    Update ${APPLICATION_NAME} to the latest stable commits
${C["UsageCommand"]-}-u --update${NC-} ${C["UsageBranch"]-}<branch>${NC-}
    Update ${APPLICATION_NAME} to the latest commits from the specified branch
EOF
            ;;&
        -V | --version | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-V --version${NC-}
    Display version information
EOF
            ;;&
        "")
            if [[ -z ${NoHeading-} ]]; then
                cat << EOF

Menu Commands:

EOF
            fi
            ;;&
        -M | --menu | "")
            Found=1
            #${C["UsageCommand"]-}-M --menu${NC-} < config-global | global >${NC-}
            #    Load the Global Configutation page in the menu.
            #${C["UsageCommand"]-}-M --menu${NC-} < ${C["UsageOption"]-}config-apps${NC-} | ${C["UsageOption"]-}apps${NC-} >${NC-}
            #    Load the ${C["UsagePage"]-}Application Configuration${NC-} page in the menu.
            cat << EOF
${C["UsageCommand"]-}-M --menu${NC-}
    Start the menu system.
    This is the same as typing '${C["UsageCommand"]-}ds${NC-}'.
${C["UsageCommand"]-}-M --menu${NC-} < ${C["UsageOption"]-}main${NC-} | ${C["UsageOption"]-}config${NC-} | ${C["UsageOption"]-}options${NC-} >${NC-}
    Load the specified page in the menu.
${C["UsageCommand"]-}-M --menu${NC-} < ${C["UsageOption"]-}options-display${NC-} | ${C["UsageOption"]-}display${NC-} >${NC-}
    Load the ${C["UsagePage"]-}Display Options${NC-} page in the menu.
${C["UsageCommand"]-}-M --menu${NC-} < ${C["UsageOption"]-}options-theme${NC-} | ${C["UsageOption"]-}theme${NC-} >${NC-}
    Load the ${C["UsagePage"]-}Theme Chooser${NC-} page in the menu.
${C["UsageCommand"]-}-M --menu${NC-} < ${C["UsageOption"]-}config-app-select${NC-} | ${C["UsageOption"]-}app-select${NC-} | ${C["UsageOption"]-}select${NC-} >${NC-}
    Load the ${C["UsagePage"]-}Application Selection${NC-} page in the menu.
EOF
            ;;&
        -S | --select | --menu-config-app-select | --menu-app-select | "")
            Found=1
            cat << EOF
${C["UsageCommand"]-}-S --select${NC-}
    Load the ${C["UsagePage"]-}Application Selection${NC-} page in the menu.
EOF
            ;;&
        *)
            if [[ -z ${Found-} ]]; then
                cat << EOF
Unknown option '${C["UsageCommand"]-}${Option}${NC-}'.
EOF
            fi
            ;;
    esac
}
