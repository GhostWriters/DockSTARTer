#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

usage() {
    local APPLICATION_HEADING="${APPLICATION_NAME}"
    if [[ ${APPLICATION_VERSION-} ]]; then
        APPLICATION_HEADING+=" [${C["Version"]-}${APPLICATION_VERSION}${NC-}]"
    fi
    if ds_update_available; then
        APPLICATION_HEADING+=" (${C["Update"]-}Update Available${NC-})"
    fi
    cat << EOF
Usage: ${APPLICATION_COMMAND} [<OPTION> ...]
NOTE: ${APPLICATION_COMMAND} shortcut is only available after the first run of
    bash main.sh

${APPLICATION_HEADING}
This is the main ${APPLICATION_NAME} script.
For regular usage you can run without providing any options.

Any command that takes a variable name, the variable name can also be in the
form of 'app:var' to refer to the variable '<var>' in '.env.app.<app>'.  Some commands
that take app names can use the form 'app:' to refer to the same file.

-a --add <app> [<app> ...]
    Add the default '.env' variables for the app(s) specified
-c --compose <pull/up/down/stop/restart/update> [<app> ...]
    Run docker compose commands. If no command is given, does an update.
    Update is the same as a 'pull' followed by an 'up'
-c --compose <generate/merge>
    Generates the docker-compose.yml file
-e --env
    Update your '.env' file with new variables
--env-appvars <app> [<app> ...]
    List all variable names for the app(s) specified
--env-appvars-lines <app> [<app> ...]
    List all variables and values for the app(s) specified
--env-get <var> [<var> ...]
--env-get=<var>
    Get the value of a <var>iable in '.env' (variable name is forced to UPPER CASE)
--env-get-line <var> [<var> ...]
--env-get-line=<var>
    Get the line of a <var>iable in '.env' (variable name is forced to UPPER CASE)
--env-get-literal <var> [<var> ...]
--env-get-literal=<var>
    Get the literal value (including quotes) of a <var>iable in '.env' (variable name is forced to UPPER CASE)
--env-get-lower <var> [<var> ...]
--env-get-lower=<var>
    Get the value of a <var>iable in .env
--env-get-lower-line <var> [<var> ...]
--env-get-lower-line=<var>
    Get the line of a <var>iable in .env
--env-get-lower-literal <var> [<var> ...]
--env-get-lower-literal=<var>
    Get the literal value (including quotes) of a <var>iable in .env
--env-set <var>=<val>
--env-set=<var>,<val>
    Set the <val>ue of a <var>iable in '.env' (variable name is forced to UPPER CASE)
--env-set-lower <var>=<val>
--env-set-lower=<var>,<val>
    Set the <val>ue of a <var>iable in .env
-f --force
    Force certain install/upgrade actions to run even if they would not be needed
-g --gui
    Use dialog boxes
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
    List referenced apps (whether they are "built in" or not)
    An app is considered "referenced" if there is a variable matching the app's name in the
    global '.env' file, or there are any variables in the file '.env.app<appname>'.
-h --help
    Show this usage information
-i --install
    Install/update all dependencies
-p --prune
    Remove unused docker resources
-r --remove
    Prompt to remove '.env' variables for all disabled apps
-r --remove <appname>
    Prompt to remove the '.env' variables for the app specified
-R --reset
    Resets ${APPLICATION_NAME} to always process environment files.
    This is usually not needed unless you have modified application templates yourself.
-s --status <appname>
    Returns the enabled/disabled status for the app specified
-S --select
    Bring up the application selection menu
--status-disable <appname>
    Disable the app specified
--status-enable <appname>
    Enable the app specified
-t --test <test_name>
    Run tests to check the program
-T --theme <themename>
    Applies the specified theme to the GUI
--theme-list
    Lists the available themes
--theme-table
    Lists the available themes in a table format
--theme-lines
--theme-no-lines
    Turn the line drawing characters on or off in the GUI
--theme-borders
--theme-no-borders
    Turn the borders on and off inthe  GUI
--theme-shadows
--theme-no-shadows
    Turn the shadows on or off in the GUI
--theme-scrollbar
--theme-no-scrollbar
    Turn the scrollbar on or off in the GUI
-u --update
    Update ${APPLICATION_NAME} to the latest stable commits
-u --update <branch>
    Update ${APPLICATION_NAME} to the latest commits from the specified branch
-v --verbose
    Verbose
-V --version
    Display version information
-x --debug
    Debug
EOF
}
