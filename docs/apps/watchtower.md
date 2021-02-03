# Watchtower

[![Docker Pulls](https://img.shields.io/docker/pulls/containrrr/watchtower?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/containrrr/watchtower)
[![GitHub Stars](https://img.shields.io/github/stars/containrrr/watchtower?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/containrrr/watchtower)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/watchtower)

## Description

[Watchtower](https://containrrr.dev/watchtower/) can update the running version of your containerized app simply by pushing a new image to the Docker Hub or your own image registry. Watchtower will pull down your new image, gracefully shut down your existing container and restart it with the same options that were used when it was deployed initially.

## Install/Setup

### Notifications

The default notification library is [Shoutrrr](https://containrrr.dev/shoutrrr/). Shoutrrr offers notifications via Discord, Email, Pushover, Slack, Telegram, and [several others](https://containrrr.dev/shoutrrr/services/overview/). Click on the service for a more thorough explanation.

| Notification Application | Your DockSTARTer `WATCHTOWER_NOTIFICATION_URL` should follow this: |
| ------------- |----------------------------------------------------------------------------------------------|
| [Discord](https://containrrr.dev/shoutrrr/services/discord/) | discord://__token__@__channel__ |
| [Email](https://containrrr.dev/shoutrrr/services/overview/) | smtp://__`username`__:__`password`__@__`host`__:__`port`__/?fromAddress=__`fromAddress`__&toAddresses=__`recipient1`__[,__`recipient2`__,...] |
| [Pushover](https://containrrr.dev/shoutrrr/services/pushover/) | pushover://shoutrrr:__`apiToken`__@__`userKey`__/?devices=__`device1`__[,__`device2`__, ...] |
 [Slack](./not-documented.md)      | *slack://[__`botname`__@]__`token-a`__/__`token-b`__/__`token-c`__* |
| [Telegram](https://containrrr.dev/shoutrrr/services/telegram/) | telegram://__`token`__@telegram?channels=__`channel-1`__[,__`channel-2`__,...] |
