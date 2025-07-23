# Watchtower

[![Docker Pulls](https://img.shields.io/docker/pulls/containrrr/watchtower?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/containrrr/watchtower)
[![GitHub Stars](https://img.shields.io/github/stars/containrrr/watchtower?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/containrrr/watchtower)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/compose/.apps/watchtower)

## Description

[Watchtower](https://containrrr.dev/watchtower/) can update the running version
of your containerized app simply by pushing a new image to the Docker Hub or
your own image registry. Watchtower will pull down your new image, gracefully
shut down your existing container and restart it with the same options that were
used when it was deployed initially.

## Install/Setup

This application does not have any specific setup instructions documented. If
you need assistance setting up this application please visit our
[support page](https://dockstarter.com/basics/support/).

### Notifications

The default notification library is [Shoutrrr](https://containrrr.dev/shoutrrr/). Shoutrrr offers notifications via Discord, Email, Pushover, Slack, Telegram, and [several others](https://containrrr.dev/shoutrrr/services/overview/). Click on the service for a more thorough explanation.

| Notification Application                                       | Your DockSTARTer `WATCHTOWER_NOTIFICATION_URL` should follow this:                                                                            |
| -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| [Discord](https://containrrr.dev/shoutrrr/services/discord/)   | discord://**token**@**channel**                                                                                                               |
| [Email](https://containrrr.dev/shoutrrr/services/overview/)    | smtp://**`username`**:**`password`**@**`host`**:**`port`**/?fromAddress=**`fromAddress`**&toAddresses=**`recipient1`**[,**`recipient2`**,...] |
| [Pushover](https://containrrr.dev/shoutrrr/services/pushover/) | pushover://shoutrrr:**`apiToken`**@**`userKey`**/?devices=**`device1`**[,**`device2`**, ...]                                                  |
| [Slack](./not-documented.md)                                   | slack://[**`botname`**@]**`token-a`**/**`token-b`**/**`token-c`**\*                                                                           |
| [Telegram](https://containrrr.dev/shoutrrr/services/telegram/) | telegram://**`token`**@telegram?channels=**`channel-1`**[,**`channel-2`**,...]                                                                |
