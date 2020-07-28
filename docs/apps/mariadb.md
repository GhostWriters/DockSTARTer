# MariaDB

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/mariadb?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/mariadb)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-mariadb?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-mariadb)

## Description

[MariaDB](https://mariadb.org/) is one of the most popular database servers. Made by the original developers of MySQL.

### Configuring MariaDB

For security purposes you need to set a root password after adding the container. You can do this my editing the `.env` file located at `~/.docker/compose/.env`. Look for this line `MARIADB_MYSQL_ROOT_PASSWORD`. However, while documenting usage of this app we noticed that if you set a password in `MARIADB_MYSQL_ROOT_PASSWORD` and `PHPMYADMIN_PMA_PASSWORD` after running `ds -c up` the variable `PHPMYADMIN_PMA_PASSWORD` does not update the necessary files inside the `phpmyadmin` container.

Our recommendation to avoid headaches is to follow these steps:

1. From your terminal run `ds -a phpmyadmin && ds -a mariadb`
2. Open your `.env` file and paste your password to `MARIADB_MYSQL_ROOT_PASSWORD` and `PHPMYADMIN_PMA_PASSWORD`. Save the file.
3. From your terminal run `ds -c up`

**Note: The root password cannot be longer than 32 characters ([Source](https://bugs.mysql.com/bug.php?id=43439)). We also noticed that [phpMyAdmin](https://dockstarter.com/apps/phpmyadmin) will not work with complex passwords longer than 16 characters. It seems to only support uppercase, lowercase and numbers.**

You can create and manage databases directly from inside the MariaDB container but we recommend you use [phpMyAdmin](https://dockstarter.com/apps/phpmyadmin) to manage your databases.

We **heavily** recommend that if you spin up a container that requires a database you create a user for that container. We will explain how to do that on the [phpMyAdmin](https://dockstarter.com/apps/phpmyadmin) page. You should **NEVER** use the root account for anything other than database management.
