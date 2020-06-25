# MariaDB

[MariaDB](https://mariadb.org/) is one of the most popular database servers. Made by the original developers of MySQL.

The GIT Repository for MariaDB is located at [https://github.com/linuxserver/docker-mariadb](https://github.com/linuxserver/docker-mariadb).

For security purposes you need to set a root password after adding the container. You can do this my editing the `.env` file located at `~/.docker/compose/.env`. Look for this line `MARIADB_MYSQL_ROOT_PASSWORD`. However, while documenting usage of this app we noticed that if you set a password in `MARIADB_MYSQL_ROOT_PASSWORD` and `PHPMYADMIN_PMA_PASSWORD` after running `ds -c up` the variable `PHPMYADMIN_PMA_PASSWORD` does not update the necessary files inside the `phpmyadmin` container. Our recommendation is to follow these steps:

1. From your terminal run `ds -a phpmyadmin && ds -a mariadb`
2. Open your `.env` file and paste your password to `MARIADB_MYSQL_ROOT_PASSWORD` and `PHPMYADMIN_PMA_PASSWORD`. Save the file.
3. From your terminal run `ds -c up`

**Note: The root password cannot be longer than 32 characters ([Source](https://bugs.mysql.com/bug.php?id=43439)). We also noticed that [phpMyAdmin](https://dockstarter.com/apps/phpmyadmin) will not work with complex passwords longer than 16 characters. It seems to only support uppercase, lowercase and numbers.**

You can create and manage databases directly from inside the MariaDB container but we recommend you use [phpMyAdmin](https://dockstarter.com/apps/phpmyadmin) to manage your databases.
