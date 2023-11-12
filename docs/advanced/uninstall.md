# Uninstalling

Blurb from our Discord follows:

> ... you can remove everything in `~/.docker` with exception to `~/.docker/config` (which you may not have if your config is at `~/.config/appdata`). However, you may want to consider keeping the `~/.docker/compose/docker-compose.yml` and `~/.docker/compose/.env` to rebuild it using `sudo docker-compose` and pass the envs.
>
> ... you should see your containers in `docker ps -a` or GUI such as Portainer.
>
> DS installs everything by running docker compose the way docker recommends, so all DS is really doing is merging a compose file together for you. Once you have the compose file you can remove DS if you like. Also DS itself doesn't do anything on its own, so you could just leave it in place. Keep up with your .env file and your config folder and everything can be done using the official compose commands.
>
> Just save any configurations you decide you need to keep, and delete the `~/.docker` folder. DockSTARTer installs docker using get.docker.com so you can read through that to undo it if you decide you need to. Compose is run via a docker container, so there's nothing to uninstall.

Note: The above has been updated and modified with more recent info.
