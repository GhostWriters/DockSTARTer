#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -rx APPLICATION_NAME='DockSTARTer'
declare -rx APPLICATION_COMMAND='ds'
declare -rx APPLICATION_REPO='https://github.com/GhostWriters/DockSTARTer'
declare -rx SOURCE_BRANCH='master'
declare -rx TARGET_BRANCH='main'

export LC_ALL=C
export PROMPT="CLI"
export MENU=false

declare -Ax PROCESSED_APPVARS_CREATE=()
declare -Ax PROCESSED_ENV_UPDATE=()

declare -arx PM_COMMAND_DEPS=(
    "column"
    "curl"
    "dialog"
    "envsubst"
    "git"
    "grep"
    "sed"
)

declare -arx PM_PACKAGE_BLACKLIST=(
    "9base"
    "busybox-grep"
    "busybox-sed"
    "curl-minimal"
    "gitlab-shell"
)

# System Information
ARCH=$(uname -m)
readonly ARCH
export ARCH

# Environment Information
declare -rx COMPOSE_FOLDER_NAME="compose"
declare -rx THEME_FOLDER_NAME=".themes"
declare -rx COMPOSE_FOLDER="${SCRIPTPATH}/${COMPOSE_FOLDER_NAME}"
declare -rx THEME_FOLDER="${SCRIPTPATH}/${THEME_FOLDER_NAME}"

declare -rx INSTANCES_FOLDER_NAME=".instances"
declare -rx TEMPLATES_FOLDER_NAME=".apps"
declare -rx APP_ENV_FOLDER_NAME="env_files"
declare -rx DOCKER_COMPOSE_FILE="${COMPOSE_FOLDER}/docker-compose.yml"
declare -rx COMPOSE_OVERRIDE_NAME="docker-compose.override.yml"
declare -rx COMPOSE_ENV="${COMPOSE_FOLDER}/.env"
declare -rx COMPOSE_ENV_DEFAULT_FILE="${COMPOSE_FOLDER}/.env.example"
declare -rx COMPOSE_OVERRIDE="${COMPOSE_FOLDER}/${COMPOSE_OVERRIDE_NAME}"
declare -rx APP_ENV_FOLDER="${COMPOSE_FOLDER}/${APP_ENV_FOLDER_NAME}"
declare -rx TEMPLATES_FOLDER="${COMPOSE_FOLDER}/${TEMPLATES_FOLDER_NAME}"
declare -rx INSTANCES_FOLDER="${COMPOSE_FOLDER}/${INSTANCES_FOLDER_NAME}"
declare -rx TIMESTAMPS_FOLDER="${COMPOSE_FOLDER}/.timestamps"

# User/Group Information
readonly DETECTED_PUID=${SUDO_UID:-$UID}
export DETECTED_PUID
DETECTED_UNAME=$(id -un "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_UNAME
export DETECTED_UNAME
DETECTED_PGID=$(id -g "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_PGID
export DETECTED_PGID
DETECTED_UGROUP=$(id -gn "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_UGROUP
export DETECTED_UGROUP
DETECTED_HOMEDIR=$(eval echo "~${DETECTED_UNAME}" 2> /dev/null || true)
readonly DETECTED_HOMEDIR
export DETECTED_HOMEDIR

# Terminal Colors
declare -Agr B=( # Background
    [B]=$(tput setab 4 2> /dev/null || echo -e "\e[44m") # Blue
    [C]=$(tput setab 6 2> /dev/null || echo -e "\e[46m") # Cyan
    [G]=$(tput setab 2 2> /dev/null || echo -e "\e[42m") # Green
    [K]=$(tput setab 0 2> /dev/null || echo -e "\e[40m") # Black
    [M]=$(tput setab 5 2> /dev/null || echo -e "\e[45m") # Magenta
    [R]=$(tput setab 1 2> /dev/null || echo -e "\e[41m") # Red
    [W]=$(tput setab 7 2> /dev/null || echo -e "\e[47m") # White
    [Y]=$(tput setab 3 2> /dev/null || echo -e "\e[43m") # Yellow
)
declare -Agr F=( # Foreground
    [B]=$(tput setaf 4 2> /dev/null || echo -e "\e[34m") # Blue
    [C]=$(tput setaf 6 2> /dev/null || echo -e "\e[36m") # Cyan
    [G]=$(tput setaf 2 2> /dev/null || echo -e "\e[32m") # Green
    [K]=$(tput setaf 0 2> /dev/null || echo -e "\e[30m") # Black
    [M]=$(tput setaf 5 2> /dev/null || echo -e "\e[35m") # Magenta
    [R]=$(tput setaf 1 2> /dev/null || echo -e "\e[31m") # Red
    [W]=$(tput setaf 7 2> /dev/null || echo -e "\e[37m") # White
    [Y]=$(tput setaf 3 2> /dev/null || echo -e "\e[33m") # Yellow
)

BD=$(tput bold 2> /dev/null || echo -e "\e[1m") # Bold
readonly BD
export BD
UL=$(tput smul 2> /dev/null || echo -e "\e[4m") # Underline
readonly UL
export UL
NC=$(tput sgr0 2> /dev/null || echo -e "\e[0m") # No Color
readonly NC
export NC
BS=$(tput cup 1000 0 2> /dev/null || true) # Bottom of screen
readonly BS
export BS

declare -Agr C=( # Pre-defined colors
    ["Timestamp"]="${NC}"
    ["Trace"]="${F[B]}"
    ["Debug"]="${F[B]}"
    ["Info"]="${F[B]}"
    ["Notice"]="${F[G]}"
    ["Warn"]="${F[Y]}"
    ["Error"]="${F[R]}"
    ["Fatal"]="${B[R]}${F[W]}"

    ["App"]="${F[C]}"
    ["Branch"]="${F[C]}"
    ["FailingCommand"]="${F[R]}"
    ["File"]="${F[C]}${BD}"
    ["Folder"]="${F[C]}${BD}"
    ["Program"]="${F[C]}"
    ["RunningCommand"]="${F[G]}${BD}"
    ["Theme"]="${F[C]}"
    ["Update"]="${F[G]}"
    ["User"]="${F[C]}"
    ["URL"]="${F[C]}${UL}"
    ["UserCommand"]="${F[Y]}${BD}"
    ["Var"]="${F[M]}"
    ["Version"]="${F[C]}"
    ["Yes"]="${F[G]}"
    ["No"]="${F[R]}"
)

declare -Ax DC

DIALOG=$(command -v dialog) || true
export DIALOG

declare -rx MENU_INI_NAME='menu.ini'
declare -rx MENU_INI_FILE="${SCRIPTPATH}/${MENU_INI_NAME}"
declare -rx THEME_FILE_NAME='theme.ini'
declare -rx DIALOGRC_NAME='.dialogrc'
declare -rx DIALOGRC="${SCRIPTPATH}/${DIALOGRC_NAME}"
declare -rx DIALOG_OPTIONS_FILE="${SCRIPTPATH}/.dialogoptions"

declare -rix DIALOGTIMEOUT=3
declare -rix DIALOG_OK=0
declare -rix DIALOG_CANCEL=1
declare -rix DIALOG_HELP=2
declare -rix DIALOG_EXTRA=3
declare -rix DIALOG_ITEM_HELP=4
declare -rix DIALOG_ERROR=254
declare -rix DIALOG_ESC=255
readonly -a DIALOG_BUTTONS=(
    [DIALOG_OK]="OK"
    [DIALOG_CANCEL]="CANCEL"
    [DIALOG_HELP]="HELP"
    [DIALOG_EXTRA]="EXTRA"
    [DIALOG_ITEM_HELP]="ITEM_HELP"
    [DIALOG_ERROR]="ERROR"
    [DIALOG_ESC]="ESC"
)
export DIALOG_BUTTONS

declare -x BACKTITLE=''
