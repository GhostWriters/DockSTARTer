# Bitwarden

[Bitwarden](https://bitwarden.com/) is a free and open-source password management service that stores sensitive information such as website credentials in an encrypted vault. This is a Bitwarden server API implementation written in Rust compatible with [upstream Bitwarden clients](https://bitwarden.com/#download), perfect for self-hosted deployment where running the official resource-heavy service might not be ideal.

The GIT Repository for Bitwarden is located at [https://github.com/dani-garcia/bitwarden_rs](https://github.com/dani-garcia/bitwarden_rs)

## Bitwarden Install

When installing the Bitwarden container, the installer will install under Appdata directory as the root user, however once it is installed you can change the owner/group of it to whatever is required

Run the below command (from a terminal) to change the permissions if required.

`sudo chown -R owner:group ~/.config/appdata/bitwarden`

Having the owner group change will allow you to edit the files if required without running into permission issues.
