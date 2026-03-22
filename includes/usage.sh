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
				local APPLICATION_HEADING="{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}}"
				if [[ ${APPLICATION_VERSION-} ]]; then
					APPLICATION_HEADING+=" [{{|Version|}}${APPLICATION_VERSION}{{[-]}}]"
				fi
				if ds_update_available; then
					APPLICATION_HEADING+=" ({{|Update|}}Update Available{{[-]}})"
				fi
				local TEMPLATES_HEADING="{{|ApplicationName|}}${TEMPLATES_NAME}{{[-]}}"
				if [[ ${TEMPLATES_VERSION-} ]]; then
					TEMPLATES_HEADING+=" [{{|Version|}}${TEMPLATES_VERSION}{{[-]}}]"
				fi
				if templates_update_available; then
					TEMPLATES_HEADING+=" ({{|Update|}}Update Available{{[-]}})"
				fi
				cat << EOF
${APPLICATION_HEADING}
${TEMPLATES_HEADING}

Usage: {{|UsageCommand|}}${APPLICATION_COMMAND}{{[-]}} [{{|UsageCommand|}}<Flags>{{[-]}}] [{{|UsageCommand|}}<Command>{{[-]}}] ...
NOTE: The '{{|UsageCommand|}}${APPLICATION_COMMAND}{{[-]}}' shortcut is only available after the first run of
	bash main.sh

This is the main {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} script.
For regular usage you can run without providing any options.

You may include multiple commands on the command-line, and they will be executed in
the order given, only stopping on an error. Any flags included only apply to the
following command, and get reset before the next command.

Any command that takes a variable name, the variable will by default be looked for
in the global '{{|UsageFile|}}.env{{[-]}}' file. If the variable name used is in form of '{{|UsageVar|}}app:var{{[-]}}', it
will instead refer to the variable '{{|UsageVar|}}<var>{{[-]}}' in '{{|UsageFile|}}.env.app.<app>{{[-]}}'.  Some commands
that take app names can use the form '{{|UsageApp|}}app:{{[-]}}' to refer to the same file.

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
{{|UsageCommand|}}-f --force{{[-]}}
	Force certain install/upgrade actions to run even if they would not be needed.
EOF
			;;&
		-g | --gui | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-g --gui{{[-]}}
	Use dialog boxes
EOF
			;;&
		-v | --verbose | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-v --verbose{{[-]}}
	Verbose
EOF
			;;&
		-x | --debug | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-x --debug{{[-]}}
	Debug
EOF
			;;&
		-y | --yes | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-y --yes{{[-]}}
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
{{|UsageCommand|}}-a --add{{[-]}} {{|UsageApp|}}<app>{{[-]}} [{{|UsageApp|}}<app>{{[-]}} ...]{{[-]}}
	Add the default variables for the app(s) specified
EOF
			;;&
		-c | --compose | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-c --compose{{[-]}} < {{|UsageOption|}}pull{{[-]}} | {{|UsageOption|}}up{{[-]}} | {{|UsageOption|}}down{{[-]}} | {{|UsageOption|}}stop{{[-]}} | {{|UsageOption|}}restart{{[-]}} | {{|UsageOption|}}pause{{[-]}} | {{|UsageOption|}}unpause{{[-]}} | {{|UsageOption|}}update{{[-]}} > [{{|UsageApp|}}<app>{{[-]}} ...]{{[-]}}
	Run docker compose commands. If no command is given, it does an '{{|UsageOption|}}update{{[-]}}'.
	The '{{|UsageOption|}}update{{[-]}}' command is the same as a '{{|UsageOption|}}pull{{[-]}}' followed by an '{{|UsageOption|}}up{{[-]}}'
{{|UsageCommand|}}-c --compose{{[-]}} < {{|UsageOption|}}generate{{[-]}} | {{|UsageOption|}}merge{{[-]}} >{{[-]}}
	Generates the '{{|UsageFile|}}docker-compose.yml{{[-]}} file
EOF
			;;&
		--config-pm | --config-pm-auto | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--config-pm{{[-]}} {{|UsageOption|}}<package manager>{{[-]}}
	Select the specified package manager to install dependencies
{{|UsageCommand|}}--config-pm-auto{{[-]}}
	Autodetect the package manager
EOF
			;;&
		--config-pm-list | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--config-pm-list{{[-]}}
	Lists the compatible package managers
EOF
			;;&
		--config-pm-table | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--config-pm-table{{[-]}}
	Lists the compatible package managers in a table format
EOF
			;;&
		--config-pm-existing-list | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--config-pm-existing-list{{[-]}}
	Lists the existing package managers
EOF
			;;&
		--config-pm-existing-table | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--config-pm-existing-table{{[-]}}
	Lists the existing package managers in a table format
EOF
			;;&
		--config-show | --show-config | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--config-show{{[-]}}
{{|UsageCommand|}}--show-config{{[-]}}
	Shows the current configuration options
EOF
			;;&
		-e | --env | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-e --env{{[-]}}
	Update your '{{|UsageFile|}}.env{{[-]}}' files with new variables
EOF
			;;&
		--env-appvars | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--env-appvars{{[-]}} {{|UsageApp|}}<app>{{[-]}} [{{|UsageApp|}}<app>{{[-]}} ...]{{[-]}}
	List all variable names for the app(s) specified
EOF
			;;&
		--env-appvars-lines | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--env-appvars-lines{{[-]}} {{|UsageApp|}}<app>{{[-]}} [{{|UsageApp|}}<app>{{[-]}} ...]{{[-]}}
	List all variables and values for the app(s) specified
EOF
			;;&
		--env-get | --env-get= | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--env-get{{[-]}} {{|UsageVar|}}<var>{{[-]}} [{{|UsageVar|}}<var>{{[-]}} ...]{{[-]}}
{{|UsageCommand|}}--env-get={{[-]}}{{|UsageVar|}}<var>{{[-]}}
	Get the value of a {{|UsageVar|}}<var>{{[-]}}iable (variable name is forced to UPPER CASE)
EOF
			;;&
		--env-get-line | --env-get-line= | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--env-get-line{{[-]}} {{|UsageVar|}}<var>{{[-]}} [{{|UsageVar|}}<var>{{[-]}} ...]{{[-]}}
{{|UsageCommand|}}--env-get-line={{[-]}}{{|UsageVar|}}<var>{{[-]}}
	Get the line of a {{|UsageVar|}}<var>{{[-]}}iable (variable name is forced to UPPER CASE)
EOF
			;;&
		--env-get-literal | --env-get-literal= | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--env-get-literal{{[-]}} {{|UsageVar|}}<var>{{[-]}} [{{|UsageVar|}}<var>{{[-]}} ...]{{[-]}}
{{|UsageCommand|}}--env-get-literal{{[-]}}={{|UsageVar|}}<var>{{[-]}}
	Get the literal value (including quotes) of a {{|UsageVar|}}<var>{{[-]}}iable (variable name is forced to UPPER CASE)
EOF
			;;&
		--env-get-lower | --env-get-lower= | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--env-get-lower{{[-]}} {{|UsageVar|}}<var>{{[-]}} [{{|UsageVar|}}<var>{{[-]}} ...]{{[-]}}
{{|UsageCommand|}}--env-get-lower{{[-]}}={{|UsageVar|}}<var>{{[-]}}
	Get the value of a {{|UsageVar|}}<var>{{[-]}}iable
EOF
			;;&
		--env-get-lower-line | --env-get-lower-line= | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--env-get-lower-line{{[-]}} {{|UsageVar|}}<var>{{[-]}} [{{|UsageVar|}}<var>{{[-]}} ...]
{{|UsageCommand|}}--env-get-lower-line={{[-]}}{{|UsageVar|}}<var>{{[-]}}
	Get the line of a {{|UsageVar|}}<var>{{[-]}}iable
EOF
			;;&
		--env-get-lower-literal | --env-get-lower-literal= | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--env-get-lower-literal{{[-]}} {{|UsageVar|}}<var>{{[-]}} [{{|UsageVar|}}<var>{{[-]}} ...]{{[-]}}
{{|UsageCommand|}}--env-get-lower-literal={{[-]}}{{|UsageVar|}}<var>{{[-]}}
	Get the literal value (including quotes) of a {{|UsageVar|}}<var>{{[-]}}iable
EOF
			;;&
		--env-set | --env-set= | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--env-set{{[-]}} {{|UsageVar|}}<var>=<val>{{[-]}}
{{|UsageCommand|}}--env-set={{[-]}}{{|UsageVar|}}<var>,<val>{{[-]}}
	Set the {{|UsageVar|}}<val>{{[-]}}ue of a {{|UsageVar|}}<var>{{[-]}}iable (variable name is forced to UPPER CASE).
EOF
			;;&
		--env-set-lower | --env-set-lower= | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--env-set-lower{{[-]}} {{|UsageVar|}}<var>=<val>{{[-]}}
{{|UsageCommand|}}--env-set-lower={{[-]}}{{|UsageVar|}}<var>,<val>{{[-]}}
	Set the {{|UsageVar|}}<val>{{[-]}}ue of a {{|UsageVar|}}<var>{{[-]}}iable
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
{{|UsageCommand|}}-l --list{{[-]}}
	List all apps
{{|UsageCommand|}}--list-added{{[-]}}
	List added apps
{{|UsageCommand|}}--list-builtin{{[-]}}
	List builtin apps
{{|UsageCommand|}}--list-deprecated{{[-]}}
	List deprecated apps
{{|UsageCommand|}}--list-enabled{{[-]}}
	List enabled apps
{{|UsageCommand|}}--list-disabled{{[-]}}
	List disabled apps
{{|UsageCommand|}}--list-nondeprecated{{[-]}}
	List non-deprecated apps
{{|UsageCommand|}}--list-referenced{{[-]}}
	List referenced apps (whether they are "built in" or not). An app is considered
	"referenced" if there is a variable matching the app's name in the global '{{|UsageFile|}}.env{{[-]}}',
	there are any variables in the file '{{|UsageFile|}}.env.app.<app>{{[-]}}', or the file '{{|UsageFile|}}.env.app.<app>{{[-]}}'
	is referenced in '{{|UsageFile|}}docker-compose.override.yml{{[-]}}'.
EOF
			;;&
		-h | --help | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-h --help{{[-]}}
	Show this usage information
{{|UsageCommand|}}-h --help{{[-]}} {{|UsageOption|}}<option>{{[-]}}
	Show the usage of the specified option
EOF
			;;&
		-i | --install | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-i --install{{[-]}}
	Install/update all dependencies
EOF
			;;&
		-p | --prune | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-p --prune{{[-]}}
	Remove unused docker resources
EOF
			;;&
		-r | --remove | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-r --remove{{[-]}}
	Prompt to remove variables for all disabled apps
{{|UsageCommand|}}-r --remove{{[-]}} {{|UsageApp|}}<app>{{[-]}} [{{|UsageApp|}}<app>{{[-]}} ...]{{[-]}}
	Prompt to remove the variables for the app specified
EOF
			;;&
		-R | --reset | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-R --reset{{[-]}}
	Resets {{|ApplicationName|}}${APPLICATION_NAME} to always process environment files.
	This is usually not needed unless you have modified application templates yourself.
EOF
			;;&
		-s | --status | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-s --status{{[-]}} {{|UsageApp|}}<app>{{[-]}} [{{|UsageApp|}}<app>{{[-]}} ...]{{[-]}}
	Returns the enabled/disabled status for the app specified
EOF
			;;&
		--status-disable) ;&
		--status-enable) ;&
		"")
			Found=1
			cat << EOF
{{|UsageCommand|}}--status-disable{{[-]}} {{|UsageApp|}}<app>{{[-]}} [{{|UsageApp|}}<app>{{[-]}} ...]{{[-]}}
	Disable the app specified
{{|UsageCommand|}}--status-enable{{[-]}} {{|UsageApp|}}<app>{{[-]}} [{{|UsageApp|}}<app>{{[-]}} ...]{{[-]}}
	Enable the app specified
EOF
			;;&
		-t | --test | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-t --test{{[-]}} {{|UsageFile|}}<test_name>{{[-]}}
	Run tests to check the program
EOF
			;;&
		-T | --theme | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-T --theme{{[-]}}
	Re-applies the current theme to the GUI
{{|UsageCommand|}}-T --theme{{[-]}} {{|UsageTheme|}}<themename>{{[-]}}
	Applies a named embedded theme
{{|UsageCommand|}}-T --theme{{[-]}} {{|UsageTheme|}}user:<themename>{{[-]}}
	Applies a user theme from the user themes folder
{{|UsageCommand|}}-T --theme{{[-]}} {{|UsageTheme|}}<path>.dstheme{{[-]}}
{{|UsageCommand|}}-T --theme{{[-]}} {{|UsageTheme|}}file:<path>{{[-]}}
	Applies a theme from an arbitrary file path
EOF
			;;&
		-T | --theme | "") ;&
		--theme-list | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--theme-list{{[-]}}
	Lists the available themes
EOF
			;;&
		-T | --theme | "") ;&
		--theme-table | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--theme-table{{[-]}}
	Lists the available themes in a table format
EOF
			;;&
		-T | --theme | "") ;&
		--theme-lines | --theme-no-lines | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--theme-lines{{[-]}}
{{|UsageCommand|}}--theme-no-lines{{[-]}}
	Turn the line drawing characters on or off in the GUI
EOF
			;;&
		-T | --theme | "") ;&
		--theme-borders | --theme-no-borders | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--theme-borders{{[-]}}
{{|UsageCommand|}}--theme-no-borders{{[-]}}
	Turn the borders on and off in the GUI
EOF
			;;&
		-T | --theme | "") ;&
		--theme-shadows | --theme-no-shadows | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--theme-shadows{{[-]}}
{{|UsageCommand|}}--theme-no-shadows{{[-]}}
	Turn the shadows on or off in the GUI
EOF
			;;&
		-T | --theme | "") ;&
		--theme-scrollbar | --theme-no-scrollbar | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--theme-scrollbar{{[-]}}
{{|UsageCommand|}}--theme-no-scrollbar{{[-]}}
	Turn the scrollbar on or off in the GUI
EOF
			;;&
		-T | --theme | "") ;&
		--theme-extract | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--theme-extract{{[-]}} {{|UsageTheme|}}<themename>{{[-]}} {{|UsageOption|}}<destdir>{{[-]}} {{|UsageOption|}}<filename>{{[-]}}
	Extract a theme to a file (use {{|UsageTheme|}}user:<name>{{[-]}} for user themes; {{|UsageOption|}}user:{{[-]}} as destdir for the user themes folder)
EOF
			;;&
		-T | --theme | "") ;&
		--theme-extract-all | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}--theme-extract-all{{[-]}} {{|UsageOption|}}<destdir>{{[-]}}
	Extract all embedded themes to a directory (use {{|UsageOption|}}user:{{[-]}} for the user themes folder)
EOF
			;;&
		-u | --update | "") ;&
		--update-app | "") ;&
		--update-templates | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-u --update{{[-]}}
	Update {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} and {{|ApplicationName|}}${TEMPLATES_NAME}{{[-]}} to the latest commits from the current branch
{{|UsageCommand|}}-u --update{{[-]}} {{|UsageBranch|}}<AppRef>{{[-]}} {{|UsageBranch|}}<TemplateRef>{{[-]}}
	Update {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} and {{|ApplicationName|}}${TEMPLATES_NAME}{{[-]}} to specified branches, tags, or commits
{{|UsageCommand|}}--update-app{{[-]}}
	Update {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} to the latest commits from the current branch
{{|UsageCommand|}}--update-app{{[-]}} {{|UsageBranch|}}<AppRef>{{[-]}}
	Update {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} to the specified branch, tag, or commit
{{|UsageCommand|}}--update-templates{{[-]}}
	Update {{|ApplicationName|}}${TEMPLATES_NAME}{{[-]}} to the latest commits from the current branch
{{|UsageCommand|}}--update-templates{{[-]}} {{|UsageBranch|}}<TemplateRef>{{[-]}}
	Update {{|ApplicationName|}}${TEMPLATES_NAME}{{[-]}} to the specified branch, tag, or commit
EOF
			;;&
		-V | --version | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-V --version{{[-]}}
	Display version information
{{|UsageCommand|}}-V --version{{[-]}} {{|UsageBranch|}}<AppRef>{{[-]}} {{|UsageBranch|}}<TemplateRef>{{[-]}}
	Display version information for the specified branches, tags, or commits
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
			#{{|UsageCommand|}}-M --menu{{[-]}} < config-global | global >{{[-]}}
			#    Load the Global Configutation page in the menu.
			#{{|UsageCommand|}}-M --menu{{[-]}} < {{|UsageOption|}}config-apps{{[-]}} | {{|UsageOption|}}apps{{[-]}} >{{[-]}}
			#    Load the {{|UsagePage|}}Application Configuration{{[-]}} page in the menu.
			cat << EOF
{{|UsageCommand|}}-M --menu{{[-]}}
	Start the menu system.
	This is the same as typing '{{|UsageCommand|}}ds{{[-]}}'.
{{|UsageCommand|}}-M --menu{{[-]}} < {{|UsageOption|}}main{{[-]}} | {{|UsageOption|}}config{{[-]}} | {{|UsageOption|}}options{{[-]}} >{{[-]}}
	Load the specified page in the menu.
{{|UsageCommand|}}-M --menu{{[-]}} < {{|UsageOption|}}options-display{{[-]}} | {{|UsageOption|}}display{{[-]}} >{{[-]}}
	Load the {{|UsagePage|}}Display Options{{[-]}} page in the menu.
{{|UsageCommand|}}-M --menu{{[-]}} < {{|UsageOption|}}options-theme{{[-]}} | {{|UsageOption|}}theme{{[-]}} >{{[-]}}
	Load the {{|UsagePage|}}Theme Chooser{{[-]}} page in the menu.
{{|UsageCommand|}}-M --menu{{[-]}} < {{|UsageOption|}}config-app-select{{[-]}} | {{|UsageOption|}}app-select{{[-]}} | {{|UsageOption|}}select{{[-]}} >{{[-]}}
	Load the {{|UsagePage|}}Application Selection{{[-]}} page in the menu.
EOF
			;;&
		-S | --select | --menu-config-app-select | --menu-app-select | "")
			Found=1
			cat << EOF
{{|UsageCommand|}}-S --select{{[-]}}
	Load the {{|UsagePage|}}Application Selection{{[-]}} page in the menu.
EOF
			;;&
		*)
			if [[ -z ${Found-} ]]; then
				cat << EOF
Unknown option '{{|UsageCommand|}}${Option}{{[-]}}'.
EOF
			fi
			;;
	esac
}
