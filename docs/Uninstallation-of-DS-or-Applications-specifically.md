---
layout: default
---

Blurb from our Discord follows: It's already "normal" in the sense that you can remove more or less everything in ~/.docker with exception to ~/.docker/config. However, you may want to consider keeping the ~/.docker/compose/docker-compose.yml and ~/.docker/compose/.env to rebuild it using `sudo docker-compose` and pass the envs.

Otherwise, you should see your running/created containers in `docker ps` or GUI such as Portainer.

You want to keep those specific files and folders and then you can delete everything else.
DS installs everything by running docker compose the way docker recommends, so all DS is really doing is merging a compose file together for you. Once you have the compose file you can remove DS if you like. Also DS itself doesn't do anything on its own, so you could just leave it in place. Keep up with your .env file and your config folder and everything can be done using the official compose commands.

Just save any configurations you decide you need to keep, and delete the ~/.docker folder. DockSTARTer installs docker using get.docker.com so you can read through that to undo it if you decide you need to. Compose is installed through pip, so you can uninstall that through pip (`sudo pip uninstall docker-compose`)
