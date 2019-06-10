Bitwarden Install

When installing the Bitwarden container, the installer will install under Appdata directory as the root user, however once it is installed you can change the owner/group of it to whatever is required

Run the below command (from a terminal) to change the permissions if required.

`sudo chown -R owner:group ~/.config/appdata/bitwarden`

Having the owner group change will allow you to edit the files if required without running into permission issues.
