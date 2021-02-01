# Watchtower

[![Docker Pulls](https://img.shields.io/docker/pulls/containrrr/watchtower?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/containrrr/watchtower)
[![GitHub Stars](https://img.shields.io/github/stars/containrrr/watchtower?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/containrrr/watchtower)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/watchtower)

## Description

[Watchtower](https://containrrr.dev/watchtower/) can update the running version of your containerized app simply by pushing a new image to the Docker Hub or your own image registry. Watchtower will pull down your new image, gracefully shut down your existing container and restart it with the same options that were used when it was deployed initially.

## Install/Setup

### Notifications

The default notification library is [Shoutrrr](https://containrrr.dev/shoutrrr/)
#### Shoutrrr offers notifications via *Discord/Slack*, *Pushover*, *Telegram*, *Email*, and [several others](https://containrrr.dev/shoutrrr/services/overview/).

- For Discord/Slack via [Shoutrrr](https://containrrr.dev/shoutrrr/services/discord/):

Your Discord Webhook-URL will look like this:
> https://discordapp.com/api/webhooks/__`channel`__/__`token`__  

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> discord://__`token`__@__`channel`__

Format the service URL
```
https://discordapp.com/api/webhooks/693853386302554172/W3dE2OZz4C13_4z_uHfDOoC7BqTW288s-z1ykqI0iJnY_HjRqMGO8Sc7YDqvf_KVKjhJ
                                    └────────────────┘ └──────────────────────────────────────────────────────────────────┘
                                        webhook id                                    token

discord://W3dE2OZz4C13_4z_uHfDOoC7BqTW288s-z1ykqI0iJnY_HjRqMGO8Sc7YDqvf_KVKjhJ@693853386302554172
          └──────────────────────────────────────────────────────────────────┘ └────────────────┘
                                          token                                    webhook id
```
[Instructions on "Creating a webhook in Discord" from Shoutrrr](https://containrrr.dev/shoutrrr/services/discord/#creating_a_webhook_in_discord)

- For Pushover via [Shoutrrr](https://containrrr.dev/shoutrrr/services/pushover/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
>*pushover://shoutrrr:__`apiToken`__@__`userKey`__/?devices=__`device1`__[,__`device2`__, ...]*

[Instructions on "Getting the keys from Pushover" from Shoutrrr](https://containrrr.dev/shoutrrr/services/pushover/#getting_the_keys_from_pushover)

- For Telegram via [Shoutrrr](https://containrrr.dev/shoutrrr/services/telegram/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
>*telegram://__`token`__@telegram?channels=__`channel-1`__[,__`channel-2`__,...]*

[Instructions on "Getting a token for Telegram" from Shoutrrr](https://containrrr.dev/shoutrrr/services/telegram/#getting_a_token_for_telegram)

- For Email via [Shoutrrr](https://containrrr.dev/shoutrrr/services/overview/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
>*smtp://__`username`__:__`password`__@__`host`__:__`port`__/?fromAddress=__`fromAddress`__&toAddresses=__`recipient1`__[,__`recipient2`__,...]*

- For Gotify via [Shoutrrr](https://containrrr.dev/shoutrrr/services/overview/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
>*gotify://__`gotify-host`__/__`token`__*

- For Hangouts Chat via [Shoutrrr](https://containrrr.dev/shoutrrr/services/hangouts/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> hangouts://chat.googleapis.com/v1/spaces/FOO/messages?key=bar&token=baz

[Instructions on "Creating an incoming webhook in Hangouts Chat](https://containrrr.dev/shoutrrr/services/hangouts/#creating_an_incoming_webhook_in_hangouts_chat)

- For IFTTT via [Shoutrrr](https://containrrr.dev/shoutrrr/services/overview/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
>*ifttt://__`key`__/?events=__`event1`__[,__`event2`__,...]&value1=__`value1`__&value2=__`value2`__&value3=__`value3`__*

- For Join via [Shoutrrr](https://containrrr.dev/shoutrrr/services/overview/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
>*join://shoutrrr:__`api-key`__@join/?devices=__`device1`__[,__`device2`__, ...][&icon=__`icon`__][&title=__`title`__]*

- For Mattermost via [Shoutrrr](https://containrrr.dev/shoutrrr/services/overview/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
>*mattermost://[__`username`__@]__`mattermost-host`__/__`token`__[/__`channel`__]*

- For Microsoft Teams via [Shoutrrr](https://containrrr.dev/shoutrrr/services/teams/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
>*teams://__`token-a`__/__`token-b`__/__`token-c`__*

[Instructions on "Setting up a webhook" from Shoutrrr](https://containrrr.dev/shoutrrr/services/teams/#setting_up_a_webhook)

- For Pushbullet via [Shoutrrr](https://containrrr.dev/shoutrrr/services/overview/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
>*pushbullet://__`api-token`__[/__`device`__/#__`channel`__/__`email`__]*

- For Rocketchat via [Shoutrrr](https://containrrr.dev/shoutrrr/services/rocketchat/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
>*rocketchat://[__`username`__@]__`rocketchat-host`__/__`token`__[/__`channel`&#124;`@recipient`__]*

- For Zulip Chat via [Shoutrrr](https://containrrr.dev/shoutrrr/services/zulip/):

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> zulip://__`bot-mail`__:__`bot-key`__@__`zulip-domain`__/?stream=__`name-or-id`__&topic=__`name`__
