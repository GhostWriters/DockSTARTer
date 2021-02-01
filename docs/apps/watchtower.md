# Watchtower

[![Docker Pulls](https://img.shields.io/docker/pulls/containrrr/watchtower?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/containrrr/watchtower)
[![GitHub Stars](https://img.shields.io/github/stars/containrrr/watchtower?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/containrrr/watchtower)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/watchtower)

## Description

[Watchtower](https://containrrr.dev/watchtower/) can update the running version of your containerized app simply by pushing a new image to the Docker Hub or your own image registry. Watchtower will pull down your new image, gracefully shut down your existing container and restart it with the same options that were used when it was deployed initially.

## Install/Setup

### Notifications

You can use an override for notifications to your favorite method (E-mail, Slack/Discord, MS Teams are supported in Watchtower currently):

- For Discord/Slack:

The default notification library is [shoutrrr](https://containrrr.dev/shoutrrr/)
#### URL Format

Your Discord Webhook-URL will look like this:
> https://discordapp.com/api/webhooks/__`channel`__/__`token`__  

The WATCHTOWER_NOTIFICATION_URL variable should look like this:  
> discord://__`token`__@__`channel`__

[Instructions on Creating a webhook in Discord from Shoutrrr](https://containrrr.dev/shoutrrr/services/discord/#creating_a_webhook_in_discord)

Format the service URL
```
https://discordapp.com/api/webhooks/693853386302554172/W3dE2OZz4C13_4z_uHfDOoC7BqTW288s-z1ykqI0iJnY_HjRqMGO8Sc7YDqvf_KVKjhJ
                                    └────────────────┘ └──────────────────────────────────────────────────────────────────┘
                                        webhook id                                    token

discord://W3dE2OZz4C13_4z_uHfDOoC7BqTW288s-z1ykqI0iJnY_HjRqMGO8Sc7YDqvf_KVKjhJ@693853386302554172
          └──────────────────────────────────────────────────────────────────┘ └────────────────┘
                                          token                                    webhook id
```

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
