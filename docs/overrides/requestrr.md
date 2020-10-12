# Requestrr

[![Docker Pulls](https://img.shields.io/docker/pulls/darkalfx/requestrr?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/darkalfx/requestrr)
[![GitHub Stars](https://img.shields.io/github/stars/darkalfx/requestrr?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/darkalfx/requestrr)

[Requestrr](https://github.com/darkalfx/requestrr) is a chatbot used to simplify using services like Sonarr/Radarr/Ombi via the use of chat. Current platform is Discord only, but the bot was built around the ideology of quick adaptation for new features as well as new platforms.

## Example Docker Compose Override

```yaml
version: "3.4"
services:

  requestrr:
    container_name: requestrr
    environment:
      - TZ=${TZ}
    image: darkalfx/requestrr
    logging:
      driver: json-file
      options:
        max-file: ${DOCKERLOGGING_MAXFILE}
        max-size: ${DOCKERLOGGING_MAXSIZE}
    ports:
      - 4545:4545
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${DOCKERCONFDIR}/requestrr:/root/config
      - ${DOCKERSTORAGEDIR}:/storage
```
