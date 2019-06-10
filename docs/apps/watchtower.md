**Override for Notifications to your favorite method (E-mail, Slack/Discord, MS Teams are supported in Watchtower currently):**

You would want to put this in your docker-compose.override.yml

For Discord/Slack:
```yaml
  watchtower:
    environment:
      - WATCHTOWER_NOTIFICATIONS=slack
      - WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL=https://url.discord.com/slack
      - WATCHTOWER_NOTIFICATION_SLACK_IDENTIFIER=watchtower-server-1
```
For E-Mail:
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
