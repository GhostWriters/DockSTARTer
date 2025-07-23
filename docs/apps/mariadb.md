# MariaDB

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/mariadb?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/mariadb)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-mariadb?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-mariadb)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/compose/.apps/mariadb)

## Description

[MariaDB](https://mariadb.org/) is one of the most popular database servers. Made by the original developers of MySQL.

## Install/Setup

You can create and manage databases directly from inside the MariaDB container but we recommend you use [phpMyAdmin](https://dockstarter.com/apps/phpmyadmin) to manage your databases.

We **heavily** recommend that if you spin up a container that requires a database you create a user for that container in [phpMyAdmin](https://dockstarter.com/apps/phpmyadmin). You should **NEVER** use the root account for anything other than database management.

> **Note: The root password cannot be longer than 32 characters ([Source](https://bugs.mysql.com/bug.php?id=43439)). We also noticed that [phpMyAdmin](https://dockstarter.com/apps/phpmyadmin) will not work with complex passwords longer than 16 characters. It seems to only support uppercase, lowercase and numbers.**
