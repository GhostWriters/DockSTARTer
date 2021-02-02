# Watchtower

[![Docker Pulls](https://img.shields.io/docker/pulls/containrrr/watchtower?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/containrrr/watchtower)
[![GitHub Stars](https://img.shields.io/github/stars/containrrr/watchtower?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/containrrr/watchtower)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/watchtower)

## Description

[Watchtower](https://containrrr.dev/watchtower/) can update the running version of your containerized app simply by pushing a new image to the Docker Hub or your own image registry. Watchtower will pull down your new image, gracefully shut down your existing container and restart it with the same options that were used when it was deployed initially.

## Install/Setup

### Notifications

The default notification library is [Shoutrrr](https://containrrr.dev/shoutrrr/). Shoutrrr offers notifications via Discord/Slack, Pushover, Telegram, Email, and [several others](https://containrrr.dev/shoutrrr/services/overview/).

| Notification Application | Your DockSTARTer `WATCHTOWER_NOTIFICATION_URL` should follow this: |
| ------------- |----------------------------------------------------------------------------------------------|
| [Discord/Slack](https://containrrr.dev/shoutrrr/services/discord/)	| discord://__token__@__channel__ |
| [Email](https://containrrr.dev/shoutrrr/services/overview/)	| smtp://__`username`__:__`password`__@__`host`__:__`port`__/?fromAddress=__`fromAddress`__&toAddresses=__`recipient1`__[,__`recipient2`__,...] |
| [Gotify](https://containrrr.dev/shoutrrr/services/overview/)	| gotify://__`gotify-host`__/__`token`__ |
| [Hangouts Chat](https://containrrr.dev/shoutrrr/services/hangouts/)	| hangouts://chat.googleapis.com/v1/spaces/FOO/messages?key=bar&token=baz |
| [IFTTT](https://containrrr.dev/shoutrrr/services/overview/)	| ifttt://__`key`__/?events=__`event1`__[,__`event2`__,...]&value1=__`value1`__&value2=__`value2`__&value3=__`value3`__ |
| [Join](https://containrrr.dev/shoutrrr/services/overview/)	| join://shoutrrr:__`api-key`__@join/?devices=__`device1`__[,__`device2`__, ...][&icon=__`icon`__][&title=__`title`__] |
| [Mattermost](https://containrrr.dev/shoutrrr/services/overview/)	| mattermost://[__`username`__@]__`mattermost-host`__/__`token`__[/__`channel`__] |
| [Microsoft Teams](https://containrrr.dev/shoutrrr/services/teams/)	| teams://__`token-a`__/__`token-b`__/__`token-c`__ |
| [Pushbullet](https://containrrr.dev/shoutrrr/services/overview/)	| pushbullet://__`api-token`__[/__`device`__/#__`channel`__/__`email`__] |
| [Pushover](https://containrrr.dev/shoutrrr/services/pushover/)	| pushover://shoutrrr:__`apiToken`__@__`userKey`__/?devices=__`device1`__[,__`device2`__, ...] |
| [Rocketchat](https://containrrr.dev/shoutrrr/services/rocketchat/)	| rocketchat://[__`username`__@]__`rocketchat-host`__/__`token`__[/__`channel`&#124;`@recipient`__] |
| [Telegram](https://containrrr.dev/shoutrrr/services/telegram/)	| telegram://__`token`__@telegram?channels=__`channel-1`__[,__`channel-2`__,...] |
| [Zulip Chat](https://containrrr.dev/shoutrrr/services/zulip/)	| zulip://__`bot-mail`__:__`bot-key`__@__`zulip-domain`__/?stream=__`name-or-id`__&topic=__`name`__ |

- Discord/Slack
  - First create a [Discord webhook](https://containrrr.dev/shoutrrr/services/discord/#creating_a_webhook_in_discord)
  - Your Discord Webhook-URL will look like this:
    ```
    https://discordapp.com/api/webhooks/__channel__/__token__
                                       └──────────┘└────────┘
                                        webhook id    token
    ```

- Hangouts Chat
	- First create a [Hangoust Chat webhook](https://containrrr.dev/shoutrrr/services/hangouts/#creating_an_incoming_webhook_in_hangouts_chat)

- Microsoft Teams
	- First create a [Microsoft Teams webhook](https://containrrr.dev/shoutrrr/services/teams/#setting_up_a_webhook)

- Pushover
  - First you need to [get the keys from Pushover](https://containrrr.dev/shoutrrr/services/pushover/#getting_the_keys_from_pushover)

- Telegram
  - First you will need to [get a Token for Telegram](https://containrrr.dev/shoutrrr/services/telegram/#getting_a_token_for_telegram)
  
