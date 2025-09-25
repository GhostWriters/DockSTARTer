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
Usage: ${C["UserCommand"]-}${APPLICATION_COMMAND}${NC-} [ [${C["UserCommand"]-}<Flags>${NC-}] [${C["UserCommand"]-}<Command>${NC-}] ... ]
NOTE: The '${C["UserCommand"]-}${APPLICATION_COMMAND}${NC-}' shortcut is only available after the first run of
    bash main.sh

${APPLICATION_HEADING}
This is the main ${APPLICATION_NAME} script.
For regular usage you can run without providing any options.

You may include multiple commands on the command-line, and they will be executed in
the order given, only stopping on an error. Any flags included only apply to the
following command, and get reset before the next command.

Any command that takes a variable name, the variable will by default be looked for
in the global '${C["File"]-}.env${NC-}' file. If the variable name used is in form of '${C["Var"]-}app:var${NC-}', it
will instead refer to the variable '${C["Var"]-}<var>${NC-}' in '${C["File"]-}.env.app.<app>${NC-}'.  Some commands
that take app names can use the form '${C["Var"]-}app:${NC-}' to refer to the same file.

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
${C["UserCommand"]-}-f --force${NC-}
    Force certain install/upgrade actions to run even if they would not be needed.
EOF
            ;;&
        -g | --gui | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-g --gui${NC-}
    Use dialog boxes
EOF
            ;;&
        -v | --verbose | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-v --verbose${NC-}
    Verbose
EOF
            ;;&
        -x | --debug | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-x --debug${NC-}
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
${C["UserCommand"]-}-a --add${NC-} <app> [<app> ...]${NC-}
    Add the default variables for the app(s) specified
EOF
            ;;&
        -c | --compose | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-c --compose${NC-} < pull | up | down | stop | restart | update > [<app> ...]${NC-}
    Run docker compose commands. If no command is given, does an update.
    Update is the same as a 'pull' followed by an 'up'
${C["UserCommand"]-}-c --compose${NC-} < generate | merge >${NC-}
    Generates the docker-compose.yml file
EOF
            ;;&
        -e | --env | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-e --env${NC-}
    Update your '${C["File"]-}.env${NC-}' files with new variables
EOF
            ;;&
        --env-appvars | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--env-appvars${NC-} <app> [<app> ...]${NC-}
    List all variable names for the app(s) specified
EOF
            ;;&
        --env-appvars-lines | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--env-appvars-lines${NC-} <app> [<app> ...]${NC-}
    List all variables and values for the app(s) specified
EOF
            ;;&
        --env-get | --env-get= | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--env-get${NC-} <var> [<var> ...]${NC-}
${C["UserCommand"]-}--env-get=${NC-}<var>${NC-}
    Get the value of a <var>iable (variable name is forced to UPPER CASE)
EOF
            ;;&
        --env-get-line | --env-get-line= | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--env-get-line${NC-} <var> [<var> ...]${NC-}
${C["UserCommand"]-}--env-get-line=${NC-}<var>${NC-}
    Get the line of a <var>iable (variable name is forced to UPPER CASE)
EOF
            ;;&
        --env-get-literal | --env-get-literal= | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--env-get-literal${NC-} <var> [<var> ...]${NC-}
${C["UserCommand"]-}--env-get-literal${NC-}=<var>${NC-}
    Get the literal value (including quotes) of a <var>iable (variable name is forced to UPPER CASE)
EOF
            ;;&
        --env-get-lower | --env-get-lower= | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--env-get-lower${NC-} <var> [<var> ...]${NC-}
${C["UserCommand"]-}--env-get-lower${NC-}=<var>${NC-}
    Get the value of a <var>iable
EOF
            ;;&
        --env-get-lower-line | --env-get-lower-line= | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--env-get-lower-line${NC-} <var> [<var> ...]
${C["UserCommand"]-}--env-get-lower-line=<var>${NC-}
    Get the line of a <var>iable
EOF
            ;;&
        --env-get-lower-literal | --env-get-lower-literal= | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--env-get-lower-literal${NC-} <var> [<var> ...]${NC-}
${C["UserCommand"]-}--env-get-lower-literal=${NC-}<var>${NC-}
    Get the literal value (including quotes) of a <var>iable
EOF
            ;;&
        --env-set | --env-set= | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--env-set${NC-} <var>=<val>${NC-}
${C["UserCommand"]-}--env-set=${NC-}<var>,<val>${NC-}
    Set the <val>ue of a <var>iable in '${C["File"]-}.env${NC-}' (variable name is forced to UPPER CASE).
EOF
            ;;&
        --env-set-lower | --env-set-lower= | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--env-set-lower${NC-} <var>=<val>${NC-}
${C["UserCommand"]-}--env-set-lower=${NC-}<var>,<val>${NC-}
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
${C["UserCommand"]-}-l --list${NC-}
    List all apps
${C["UserCommand"]-}--list-added${NC-}
    List added apps
${C["UserCommand"]-}--list-builtin${NC-}
    List builtin apps
${C["UserCommand"]-}--list-deprecated${NC-}
    List deprecated apps
${C["UserCommand"]-}--list-enabled${NC-}
    List enabled apps
${C["UserCommand"]-}--list-disabled${NC-}
    List disabled apps
${C["UserCommand"]-}--list-nondeprecated${NC-}
    List non-deprecated apps
${C["UserCommand"]-}--list-referenced${NC-}
    List referenced apps (whether they are "built in" or not).
    An app is considered "referenced" if there is a variable matching the app's name in the
    global '${C["File"]-}.env${NC-}' file, or there are any variables in the file '${C["File"]-}.env.app.<app>${NC-}'.
EOF
            ;;&
        -h | --help | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-h --help${NC-}
    Show this usage information
${C["UserCommand"]-}-h --help${NC-} <option>${NC-}
    Show the usage of the specified option
EOF
            ;;&
        -i | --install | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-i --install${NC-}
    Install/update all dependencies
EOF
            ;;&
        -p | --prune | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-p --prune${NC-}
    Remove unused docker resources
EOF
            ;;&
        -r | --remove | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-r --remove${NC-}
    Prompt to remove variables for all disabled apps
${C["UserCommand"]-}-r --remove${NC-} <app>${NC-}
    Prompt to remove the variables for the app specified
EOF
            ;;&
        -R | --reset | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-R --reset${NC-}
    Resets ${APPLICATION_NAME} to always process environment files.
    This is usually not needed unless you have modified application templates yourself.
EOF
            ;;&
        -s | --status | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-s --status${NC-} <app>${NC-}
    Returns the enabled/disabled status for the app specified
EOF
            ;;&
        --status-disable) ;&
        --status-enable) ;&
        "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--status-disable${NC-} <app>${NC-}
    Disable the app specified
${C["UserCommand"]-}--status-enable${NC-} <app>${NC-}
    Enable the app specified
EOF
            ;;&
        -t | --test | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-t --test${NC-} <test_name>${NC-}
    Run tests to check the program
EOF
            ;;&
        -T | --theme | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-T --theme${NC-}
    Re-applies the current theme to the GUI
${C["UserCommand"]-}-T --theme${NC-} <themename>${NC-}
    Applies the specified theme to the GUI
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-list | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--theme-list${NC-}
    Lists the available themes
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-table | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--theme-table${NC-}
    Lists the available themes in a table format
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-lines | --theme-no-lines | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--theme-lines${NC-}
${C["UserCommand"]-}--theme-no-lines${NC-}
    Turn the line drawing characters on or off in the GUI
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-borders | --theme-no-borders | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--theme-borders${NC-}
${C["UserCommand"]-}--theme-no-borders${NC-}
    Turn the borders on and off in the GUI
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-shadows | --theme-no-shadows | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--theme-shadows${NC-}
${C["UserCommand"]-}--theme-no-shadows${NC-}
    Turn the shadows on or off in the GUI
EOF
            ;;&
        -T | --theme | "") ;&
        --theme-scrollbar | --theme-no-scrollbar | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}--theme-scrollbar${NC-}
${C["UserCommand"]-}--theme-no-scrollbar${NC-}
    Turn the scrollbar on or off in the GUI
EOF
            ;;&
        -u | --update | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-u --update${NC-}
    Update ${APPLICATION_NAME} to the latest stable commits
${C["UserCommand"]-}-u --update${NC-} <branch>${NC-}
    Update ${APPLICATION_NAME} to the latest commits from the specified branch
EOF
            ;;&
        -V | --version | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-V --version${NC-}
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
            #${C["UserCommand"]-}-M --menu${NC-} < config-global | global >${NC-}
            #    Load the Global Configutation page in the menu.
            cat << EOF
${C["UserCommand"]-}-M --menu${NC-}
    Start the menu system.
    This is the same as typing 'ds'.
${C["UserCommand"]-}-M --menu${NC-} < main | config | options >${NC-}
    Load the specified page in the menu.
${C["UserCommand"]-}-M --menu${NC-} < config-apps | apps >${NC-}
    Load the Application Configuration page in the menu.
${C["UserCommand"]-}-M --menu${NC-} < options-display | display >${NC-}
    Load the Display Options page in the menu.
${C["UserCommand"]-}-M --menu${NC-} < options-theme | theme >${NC-}
    Load the Theme Chooser page in the menu.
${C["UserCommand"]-}-M --menu${NC-} < config-app-select | app-select | select >${NC-}
    Load the Theme Chooser page in the menu.
EOF
            ;;&
        -S | --select | --menu-config-app-select | --menu-app-select | "")
            Found=1
            cat << EOF
${C["UserCommand"]-}-S --select${NC-}
    Load the Application Selection page in the menu.
EOF
            ;;&
        *)
            if [[ -z ${Found-} ]]; then
                cat << EOF
Unknown option '${C["UserCommand"]-}${Option}${NC-}'.
EOF
            fi
            ;;
    esac
}
