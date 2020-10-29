# Watchtower

[![Docker Pulls](https://img.shields.io/docker/pulls/containrrr/watchtower?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/containrrr/watchtower)
[![GitHub Stars](https://img.shields.io/github/stars/containrrr/watchtower?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/containrrr/watchtower)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/watchtower)

## Description

[Watchtower](https://containrrr.dev/watchtower/) can update the running version of your containerized app simply by pushing a new image to the Docker Hub or your own image registry. Watchtower will pull down your new image, gracefully shut down your existing container and restart it with the same options that were used when it was deployed initially.

## Install/Setup

### Notifications

You can use an override for notifications to your favorite method (E-mail, Slack/Discord, MS Teams are supported in Watchtower currently):

You would want to put this in your [override](https://dockstarter.com/overrides/introduction/)

- For Discord/Slack:

```yaml
  watchtower:
    environment:
      - WATCHTOWER_NOTIFICATIONS=slack
      - WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL=https://url.discord.com/slack
      - WATCHTOWER_NOTIFICATION_SLACK_IDENTIFIER=watchtower-server-1
```

- For E-Mail:

```yaml
  watchtower:
    environment:
      - WATCHTOWER_NOTIFICATION_EMAIL_FROM=myemail@gmail.com
      - WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PASSWORD=secretPassword
      - WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PORT=587
      - WATCHTOWER_NOTIFICATION_EMAIL_SERVER_USER=myemail@gmail.com
      - WATCHTOWER_NOTIFICATION_EMAIL_SERVER=smtp.gmail.com
      - WATCHTOWER_NOTIFICATION_EMAIL_TO=myemail@gmail.com
      - WATCHTOWER_NOTIFICATIONS=email
```

This is what you **could have had** in your override **previously**:

```yaml
version: "3.4"  # this must match the version in docker-compose.yml
services:
    netdata:
      hostname: newhostname
```

So **now** your override would look like this:

```yaml
version: "3.4" # this must match the version in docker-compose.yml
services:
  netdata:
    hostname: newhostname
  watchtower:
    environment:
      - WATCHTOWER_NOTIFICATIONS=slack
      - WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL=https://url.discord.com/slack
      - WATCHTOWER_NOTIFICATION_SLACK_IDENTIFIER=watchtower-server-1
```
