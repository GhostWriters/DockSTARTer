# Watchtower

[![Docker Pulls](https://img.shields.io/docker/pulls/containrrr/watchtower?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/containrrr/watchtower)
[![GitHub Stars](https://img.shields.io/github/stars/containrrr/watchtower?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/containrrr/watchtower)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/watchtower)

## Description

[Watchtower](https://containrrr.dev/watchtower/) can update the running version of your containerized app simply by pushing a new image to the Docker Hub or your own image registry. Watchtower will pull down your new image, gracefully shut down your existing container and restart it with the same options that were used when it was deployed initially.

## Install/Setup

### Notifications

The default notification library is [Shoutrrr](https://containrrr.dev/shoutrrr/). Shoutrrr offers notifications via Discord/Slack, Pushover, Telegram, Email, and [several others](https://containrrr.dev/shoutrrr/services/overview/).

- For Discord/Slack via [Shoutrrr](https://containrrr.dev/shoutrrr/services/discord/)
  - First create a [Discord webhook](https://containrrr.dev/shoutrrr/services/discord/#creating_a_webhook_in_discord)

Your Discord Webhook-URL will look like this:

> `https://discordapp.com/api/webhooks/__channel__/__token__`

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> `discord://__token__@__channel__`

The example below provides you a visual of what you get when you first create a Discord webhook and what you need to change it to when you put it in the `WATCHTOWER_NOTIFICATION_URL` variable.

```bash
https://discordapp.com/api/webhooks/693853386302554172/W3dE2OZz4C13_4z_uHfDOoC7BqTW288s-z1ykqI0iJnY_HjRqMGO8Sc7YDqvf_KVKjhJ
                                    └────────────────┘ └──────────────────────────────────────────────────────────────────┘
                                        webhook id                                    token
```

```bash
discord://W3dE2OZz4C13_4z_uHfDOoC7BqTW288s-z1ykqI0iJnY_HjRqMGO8Sc7YDqvf_KVKjhJ@693853386302554172
          └──────────────────────────────────────────────────────────────────┘ └────────────────┘
                                          token                                    webhook id
```

- For Pushover via [Shoutrrr](https://containrrr.dev/shoutrrr/services/pushover/)
  - First you need to [get the keys from Pushover](https://containrrr.dev/shoutrrr/services/pushover/#getting_the_keys_from_pushover)

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> pushover://shoutrrr:__`apiToken`__@__`userKey`__/?devices=__`device1`__[,__`device2`__, ...]

- For Telegram via [Shoutrrr](https://containrrr.dev/shoutrrr/services/telegram/)
  - First you will need to [get a Token for Telegram](https://containrrr.dev/shoutrrr/services/telegram/#getting_a_token_for_telegram)

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> telegram://__`token`__@telegram?channels=__`channel-1`__[,__`channel-2`__,...]

- For Email via [Shoutrrr](https://containrrr.dev/shoutrrr/services/overview/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> smtp://__`username`__:__`password`__@__`host`__:__`port`__/?fromAddress=__`fromAddress`__&toAddresses=__`recipient1`__[,__`recipient2`__,...]

- For Gotify via [Shoutrrr](https://containrrr.dev/shoutrrr/services/overview/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> gotify://__`gotify-host`__/__`token`__

- For Hangouts Chat via [Shoutrrr](https://containrrr.dev/shoutrrr/services/hangouts/):
  - First create a [Hangoust Chat webhook](https://containrrr.dev/shoutrrr/services/hangouts/#creating_an_incoming_webhook_in_hangouts_chat)

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> hangouts://chat.googleapis.com/v1/spaces/FOO/messages?key=bar&token=baz

- For IFTTT via [Shoutrrr](https://containrrr.dev/shoutrrr/services/overview/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> ifttt://__`key`__/?events=__`event1`__[,__`event2`__,...]&value1=__`value1`__&value2=__`value2`__&value3=__`value3`__

- For Join via [Shoutrrr](https://containrrr.dev/shoutrrr/services/overview/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> join://shoutrrr:__`api-key`__@join/?devices=__`device1`__[,__`device2`__, ...][&icon=__`icon`__][&title=__`title`__]

- For Mattermost via [Shoutrrr](https://containrrr.dev/shoutrrr/services/overview/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> mattermost://[__`username`__@]__`mattermost-host`__/__`token`__[/__`channel`__]

- For Microsoft Teams via [Shoutrrr](https://containrrr.dev/shoutrrr/services/teams/):
  - First create a [Microsoft Teams webhook](https://containrrr.dev/shoutrrr/services/teams/#setting_up_a_webhook)

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:

> teams://__`token-a`__/__`token-b`__/__`token-c`__

- For Pushbullet via [Shoutrrr](https://containrrr.dev/shoutrrr/services/overview/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:

> pushbullet://__`api-token`__[/__`device`__/#__`channel`__/__`email`__]

- For Rocketchat via [Shoutrrr](https://containrrr.dev/shoutrrr/services/rocketchat/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> rocketchat://[__`username`__@]__`rocketchat-host`__/__`token`__[/__`channel`&#124;`@recipient`__]

- For Zulip Chat via [Shoutrrr](https://containrrr.dev/shoutrrr/services/zulip/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> zulip://__`bot-mail`__:__`bot-key`__@__`zulip-domain`__/?stream=__`name-or-id`__&topic=__`name`__
