# Watchtower

[![Docker Pulls](https://img.shields.io/docker/pulls/containrrr/watchtower?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/containrrr/watchtower)
[![GitHub Stars](https://img.shields.io/github/stars/containrrr/watchtower?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/containrrr/watchtower)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/watchtower)

## Description

[Watchtower](https://containrrr.dev/watchtower/) can update the running version of your containerized app simply by pushing a new image to the Docker Hub or your own image registry. Watchtower will pull down your new image, gracefully shut down your existing container and restart it with the same options that were used when it was deployed initially.

## Install/Setup

### Notifications

The default notification library is [Shoutrrr](https://containrrr.dev/shoutrrr/)
#### Shoutrrr offers notifications via *Discord*, *Hangout Chats*, *Pushover*, *Teams*, *Telegram*, and *Zulip Chat*.

- For [Discord/Slack](https://containrrr.dev/shoutrrr/services/discord/) via [Shoutrrr](https://containrrr.dev/shoutrrr/):

#### URL Format

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

- For [Hangouts Chat](https://containrrr.dev/shoutrrr/services/hangouts/) via [Shoutrrr](https://containrrr.dev/shoutrrr/):

#### URL Format

Your Hangouts Chat Incoming Webhook URL will look like this:
> https://chat.googleapis.com/v1/spaces/FOO/messages?key=bar&token=baz

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> hangouts://chat.googleapis.com/v1/spaces/FOO/messages?key=bar&token=baz

In other words the incoming webhook URL with `https` replaced by `hangouts`.

[Instructions on "Creating an incoming webhook in Hangouts Chat](https://containrrr.dev/shoutrrr/services/hangouts/#creating_an_incoming_webhook_in_hangouts_chat)

- For [Pushover](https://containrrr.dev/shoutrrr/services/pushover/) via [Shoutrrr](https://containrrr.dev/shoutrrr/):

#### URL Format

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
>*pushover://shoutrrr:__`apiToken`__@__`userKey`__/?devices=__`device1`__[,__`device2`__, ...]*

[Instructions on "Getting the keys from Pushover" from Shoutrrr](https://containrrr.dev/shoutrrr/services/pushover/#getting_the_keys_from_pushover)

- For [Teams](https://containrrr.dev/shoutrrr/services/teams/) via [Shoutrrr](https://containrrr.dev/shoutrrr/):

#### URL Format

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
>*teams://__`token-a`__/__`token-b`__/__`token-c`__*

[Instructions on "Setting up a webhook" from Shoutrrr](https://containrrr.dev/shoutrrr/services/teams/#setting_up_a_webhook)

- For [Telegram](https://containrrr.dev/shoutrrr/services/telegram/) via [Shoutrrr](https://containrrr.dev/shoutrrr/):

#### URL Format

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
>*telegram://__`token`__@telegram?channels=__`channel-1`__[,__`channel-2`__,...]*

[Instructions on "Getting a token for Telegram" from Shoutrrr](https://containrrr.dev/shoutrrr/services/telegram/#getting_a_token_for_telegram)

- For [Zulip Chat](https://containrrr.dev/shoutrrr/services/zulip/) via [Shoutrrr](https://containrrr.dev/shoutrrr/):

#### URL Format

The `WATCHTOWER_NOTIFICATION_URL` variable should look like this:
> zulip://__`bot-mail`__:__`bot-key`__@__`zulip-domain`__/?stream=__`name-or-id`__&topic=__`name`__

- For E-Mail:

You would want to put this in your [override](https://dockstarter.com/overrides/introduction/)

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
