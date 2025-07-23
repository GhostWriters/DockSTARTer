# TheLounge

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/thelounge?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/thelounge)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-thelounge?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-thelounge)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/compose/.apps/thelounge)

## Description

[TheLounge](https://thelounge.chat/) is a web IRC client that you host on your
own server.

## Install/Setup

- When the application first runs, it will populate its `/config`
- Stop the container
- Now from the host, edit `~/.config/appdata/thelounge/config.js`, or wherever you've mapped it
- In most cases you want the value `public: false` to allow named users only
  - This will allow for persistent connections to the servers you configure for each account
- Setting the two prefetch values to `true` improves usability, but uses more storage
- Once you have the configuration you want, save it and start the container again
- For each user, run the command
- `docker exec -it thelounge s6-setuidgid abc thelounge add <user>`
- You will be prompted to enter a password that will not be echoed.
- Saving logs to disk is the default, this consumes more space but allows scrollback.
- To log in to the application, browse to `http://<hostip>:9000`
- Other containerized applications such as organizr would use `http://<container>:9000`
- You should now be prompted for a username and password on the webinterface.
- Once logged in, you can add an IRC network. Some defaults are preset for Freenode.

If you need assistance setting up this application please visit our
[support page](https://dockstarter.com/basics/support/).
