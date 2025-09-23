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
                local APPLICATION_HEADING="${APPLICATION_NAME}"
                if [[ ${APPLICATION_VERSION-} ]]; then
                    APPLICATION_HEADING+=" [${C["Version"]-}${APPLICATION_VERSION}${NC-}]"
                fi
                if ds_update_available; then
                    APPLICATION_HEADING+=" (${C["Update"]-}Update Available${NC-})"
                fi
                cat << EOF
Usage: ${APPLICATION_COMMAND} [<Flags>] [<Command>] ...
NOTE: ${APPLICATION_COMMAND} shortcut is only available after the first run of
    bash main.sh

${APPLICATION_HEADING}
This is the main ${APPLICATION_NAME} script.
For regular usage you can run without providing any options.

You may include multiple commands on the command-line, and they will be executed in
the order given, only stopping on an error. Any flags included only apply to the
following command, and get reset before the next command.

Any command that takes a variable name, the variable will by default be looked for
in the global '.env' file. If the variable name used is in form of 'app:var', it
will instead refer to the variable '<var>' in '.env.app.<app>'.  Some commands
that take app names can use the form 'app:' to refer to the same file.

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
-f --force
    Force certain install/upgrade actions to run even if they would not be needed.
EOF
            ;;&
        -g | --gui | "")
            Found=1
            cat << EOF
-g --gui
    Use dialog boxes
EOF
            ;;&
        -v | --verbose | "")
            Found=1
            cat << EOF
-v --verbose
    Verbose
EOF
            ;;&
        -x | --debug | "")
            Found=1
            cat << EOF
-x --debug
    Debug
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
-a --add <app> [<app> ...]
    Add the default variables for the app(s) specified
EOF
            ;;&
        -c | --compose | "")
            Found=1
            cat << EOF
-c --compose < pull | up | down | stop | restart | update > [<app> ...]
    Run docker compose commands. If no command is given, does an update.
    Update is the same as a 'pull' followed by an 'up'
-c --compose < generate | merge >
    Generates the docker-compose.yml file
EOF
            ;;&
        -e | --env | "")
            Found=1
            cat << EOF
-e --env
    Update your '.env' files with new variables
EOF
            ;;&
        --env-appvars | "")
            Found=1
            cat << EOF
--env-appvars <app> [<app> ...]
    List all variable names for the app(s) specified
EOF
            ;;&
        --env-appvars-lines | "")
            Found=1
            cat << EOF
--env-appvars-lines <app> [<app> ...]
    List all variables and values for the app(s) specified
EOF
            ;;&
        --env-get | --env-get= | "")
            Found=1
            cat << EOF
--env-get <var> [<var> ...]
--env-get=<var>
    Get the value of a <var>iable (variable name is forced to UPPER CASE)
EOF
            ;;&
        --env-get-line | --env-get-line= | "")
            Found=1
            cat << EOF
--env-get-line <var> [<var> ...]
--env-get-line=<var>
    Get the line of a <var>iable (variable name is forced to UPPER CASE)
EOF
            ;;&
        --env-get-literal | --env-get-literal= | "")
            Found=1
            cat << EOF
--env-get-literal <var> [<var> ...]
--env-get-literal=<var>
    Get the literal value (including quotes) of a <var>iable (variable name is forced to UPPER CASE)
EOF
            ;;&
        --env-get-lower | --env-get-lower= | "")
            Found=1
            cat << EOF
--env-get-lower <var> [<var> ...]
--env-get-lower=<var>
    Get the value of a <var>iable
EOF
            ;;&
        --env-get-lower-line | --env-get-lower-line= | "")
            Found=1
            cat << EOF
--env-get-lower-line <var> [<var> ...]
--env-get-lower-line=<var>
    Get the line of a <var>iable
EOF
            ;;&
        --env-get-lower-literal | --env-get-lower-literal= | "")
            Found=1
            cat << EOF
--env-get-lower-literal <var> [<var> ...]
--env-get-lower-literal=<var>
    Get the literal value (including quotes) of a <var>iable
EOF
            ;;&
        --env-set | --env-set= | "")
            Found=1
            cat << EOF
--env-set <var>=<val>
--env-set=<var>,<val>
    Set the <val>ue of a <var>iable in '.env' (variable name is forced to UPPER CASE).
EOF
            ;;&
        --env-set-lower | --env-set-lower= | "")
            Found=1
            cat << EOF
--env-set-lower <var>=<val>
--env-set-lower=<var>,<val>
    Set the <val>ue of a <var>iable in .env
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
-l --list
    List all apps
--list-added
    List added apps
--list-builtin
    List builtin apps
--list-deprecated
    List deprecated apps
--list-enabled
    List enabled apps
--list-disabled
    List disabled apps
--list-nondeprecated
    List non-deprecated apps
--list-referenced
    List referenced apps (whether they are "built in" or not).
    An app is considered "referenced" if there is a variable matching the app's name in the
    global '.env' file, or there are any variables in the file '.env.app<appname>'.
EOF
            ;;&
        -h | --help | "")
            Found=1
            cat << EOF
-h --help
    Show this usage information
-h --help < Option >
    Show the usage of the specified option
EOF
            ;;&
        -i | --install | "")
            Found=1
            cat << EOF
-i --install
    Install/update all dependencies
EOF
            ;;&
        -p | --prune | "")
            Found=1
            cat << EOF
-p --prune
    Remove unused docker resources
EOF
            ;;&
        -r | --remove | "")
            Found=1
            cat << EOF
-r --remove
    Prompt to remove '.env' variables for all disabled apps
-r --remove <appname>
    Prompt to remove the '.env' variables for the app specified
EOF
            ;;&
        -R | --reset | "")
            Found=1
            cat << EOF
-R --reset
    Resets ${APPLICATION_NAME} to always process environment files.
    This is usually not needed unless you have modified application templates yourself.
EOF
            ;;&
        -s | --status | "")
            Found=1
            cat << EOF
-s --status <appname>
    Returns the enabled/disabled status for the app specified
EOF
            ;;&
        --status-disable) ;&
        --status-enable) ;&
        "")
            Found=1
            cat << EOF
--status-disable <appname>
    Disable the app specified
--status-enable <appname>
    Enable the app specified
EOF
            ;;&
        -t | --test | "")
            Found=1
            cat << EOF
-t --test <test_name>
    Run tests to check the program
EOF
            ;;&
        -T | --theme | "")
            Found=1
            cat << EOF
-T --theme <themename>
    Applies the specified theme to the GUI
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-list | "")
            Found=1
            cat << EOF
--theme-list
    Lists the available themes
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-table | "")
            Found=1
            cat << EOF
--theme-table
    Lists the available themes in a table format
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-lines | --theme-no-lines | "")
            Found=1
            cat << EOF
--theme-lines
--theme-no-lines
    Turn the line drawing characters on or off in the GUI
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-borders | --theme-no-borders | "")
            Found=1
            cat << EOF
--theme-borders
--theme-no-borders
    Turn the borders on and off in the GUI
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-shadows | --theme-no-shadows | "")
            Found=1
            cat << EOF
--theme-shadows
--theme-no-shadows
    Turn the shadows on or off in the GUI
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-scrollbar | --theme-no-scrollbar | "")
            Found=1
            cat << EOF
--theme-scrollbar
--theme-no-scrollbar
    Turn the scrollbar on or off in the GUI
EOF
            ;;&
        -u | --update | "")
            Found=1
            cat << EOF
-u --update
    Update ${APPLICATION_NAME} to the latest stable commits
-u --update <branch>
    Update ${APPLICATION_NAME} to the latest commits from the specified branch
EOF
            ;;&
        -V | --version | "")
            Found=1
            cat << EOF
-V --version
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
            #-M --menu < config-global | global >
            #    Load the Global Configutation page in the menu.
            cat << EOF
-M --menu
    Start the menu system.
    This is the same as typing 'ds'.
-M --menu < main | config | options >
    Load the specified page in the menu.
-M --menu < config-apps | apps >
    Load the Application Configuration page in the menu.
-M --menu < options-display | display >
    Load the Display Options page in the menu.
-M --menu < options-theme | theme >
    Load the Theme Chooser page in the menu.
-M --menu < config-app-select | app-select | select >
    Load the Theme Chooser page in the menu.
EOF
            ;;&
        -S | --select | --menu-config-app-select | --menu-app-select | "")
            Found=1
            cat << EOF
-S --select
    Load the Application Selection page in the menu.
EOF
            ;;&
        *)
            if [[ -z ${Found-} ]]; then
                cat << EOF
Unknown option '${Option}'.
EOF
            fi
            ;;
    esac
}
