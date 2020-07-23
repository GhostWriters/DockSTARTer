# Samba

## Description

Samba is using the `SMB` protocol to share Linux mounts, which then are accessible and mountable on a Windows computer.

By default, Samba will share all media directories and [Docker config directory](https://dockstarter.com/basics/env-var-info/#dockerconfdir) over SMB on the host. All of these directories will be placed inside whatever share name is specified for `SAMBA_SHARENAME` on your `.env` file. These shares are protected with username `ds` and password `ds` by default, but **can and should be** changed on your `.env` file.

## Access Shares

Replace `host` with your DNS or IP-address of your Docker host.

* `\\host\DockSTARTer`

## Setting Up Additional Shares

You can set up additional shares using an[override](https://dockstarter.com/overrides/introduction/). To do so, you need to do the following:

1. Create a new variable in your `.env` file that will be the path to your new share on the host e.g. `/path/to/your/share` and give it an easily recognizable name e.g. `SAMBA_xxxx=/path/to/share`.

2. Create another variable that will be the **share name** that shows up when you access your shares. For example, `SAMBA_SHARE_xxx=AnotherShare`

3. On your override file under `environment` and `volumes` you will you need to copy the following:

    ```yaml
        environment:
            - SHARE2=${SAMBA_SHARENAME};/${SAMBA_SHARENAME};yes;no;no;all;${SAMBA_USERNAME}
    ```

    ```yaml
        volumes:
            - ${SAMBA_xxx}:/path/inside/container
    ```

    * Make sure to **update what is inside `${}`** to match whatever you used in Step 2.

    * If you want to add additional shares in the future just add a number at the end of the `SHARE` and just copy and paste everything after the `=`. Don't forget to update what is inside the `${}`.

4. Run `ds -c up samba` to recreate the container and the new share can be generated.

## How To Mount Windows Share in Linux

See [SMB Mounting](https://dockstarter.com/advanced/smb-mounting/).

### Resources

#### [GitHub](https://github.com/dperson/samba)

#### [DockerHub](https://hub.docker.com/r/dperson/samba)
