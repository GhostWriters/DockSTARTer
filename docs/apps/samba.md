# Samba

## Description

Samba is using the `SMB` protocol to share Linux mounts, which then are accessible and mountable on e.g. a Windows computer.

By default, Samba will share all media directories and Docker config directory over SMB on the host. These shares are protected with username `ds` and password `ds`.

## Access Shares

Replace `host` with your DNS or IP-address of your Docker host.

* `\\host\DockSTARTer`

## Related

### Mounting Windows share in Linux

See [SMB Mounting](https://dockstarter.com/advanced/smb-mounting/).
