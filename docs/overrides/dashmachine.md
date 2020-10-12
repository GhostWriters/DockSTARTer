# dashmachine

[![Docker Pulls](https://img.shields.io/docker/pulls/rmountjoy/dashmachine?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/rmountjoy/dashmachine)
[![GitHub Stars](https://img.shields.io/github/stars/rmountjoy92/dashmachine?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/rmountjoy92/DashMachine)

## Description

[dashmachine](https://github.com/rmountjoy92/DashMachine) is a chatbot used to simplify using services like Sonarr/Radarr/Ombi via the use of chat. Current platform is Discord only, but the bot was built around the ideology of quick adaptation for new features as well as new platforms.

## Install/Setup

### Example Docker Compose Override

```yaml
version: "3.4"
services:

  dashmachine:
    container_name: dashmachine
    hostname: ${DOCKERHOSTNAME}
    image: rmountjoy/dashmachine
    logging:
      driver: json-file
      options:
        max-file: ${DOCKERLOGGING_MAXFILE}
        max-size: ${DOCKERLOGGING_MAXSIZE}
    ports:
      - 5002:5000
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKERCONFDIR}/dashmachine:/DashMachine/dashmachine/user_data
      - ${DOCKERSTORAGEDIR}:/storage
```
