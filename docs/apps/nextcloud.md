# Nextcloud

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/nextcloud?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/nextcloud)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-nextcloud?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-nextcloud)

## Description

[Nextcloud](https://nextcloud.com/) gives you access to all your files wherever you are.

## Install/Setup

### Configuring Nextcloud

If you are running the DockSTARTer Nextcloud container behind a [SWAG](https://dockstarter.com/apps/swag/) reverse proxy, you may need to add a extra line to the NextCloud config.php file so it can find it.

Without configuring this you will be able to access the web page, but apps may timeout or return an invalid password.

Run the below command and add the line to the the config.php file before the `);`

```bash
nano /config/www/nextcloud/config/config.php
```

Copy the following line:
`'overwritehost' => 'hostname',`

Where your `hostname` is the URL you use to access your NextCloud web interface, **make sure you include the comma at the end**.

Doing this will allow the apps to pass the username/password through to the application.
