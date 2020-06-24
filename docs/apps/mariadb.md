# MariaDB

[MariaDB](https://mariadb.org/) is one of the most popular database servers. Made by the original developers of MySQL.

The GIT Repository for MariaDB is located at [https://github.com/linuxserver/docker-mariadb](https://github.com/linuxserver/docker-mariadb).

You need to set up a root password after installing the container. You can do this my editing the `.env` file located at `~/.docker/compose/.env`. Look for this line `MARIADB_MYSQL_ROOT_PASSWORD`.

**Note: The root password cannot be longer than 32 characters [Source](https://bugs.mysql.com/bug.php?id=43439).**

You can create and manage databases directly from inside the MariaDB container but we recommend you use [phpMyAdmin](https://dockstarter.com/apps/phpmyadmin) to manage your databases.
