# Speedtest

## Description

This program runs a speedtest check every hour and graphs the results. The back-end is written in `Laravel` and the front-end uses React. It uses the Ookla's Speedtest cli package to get the data and uses `Chart.js` to plot the results.

This program can also be used a home page item in [Organizr](https://docs.organizr.app/).

*Disclaimer: You will need to accept Ookla's EULA and privacy agreements in order to use this container.*

### Base Path

You can set a base path for this application if you want to host it behind a reverse proxy. By default it binds to `/`, but you can change the variable called `SPEEDTEST_BASE_PATH` in your `.env` file to whatever you want and run `ds -c up speedtest` afterwards.

As usual, we **strongly discourage** having this application be public facing without some sort of protection in front of it, such as [Organizr's Server Auth](https://docs.organizr.app/books/setup-features/page/serverauth).

### Notifications

This application supports notifications to some of the most popular services such as Telegram and Discord. For Telegram, the `Bot Token` and `Telegram Chat ID` can be filled in using the Web GUI. However, for the Slack/Discord webhook it will need to be filled in using an environment variable on an [override](https://dockstarter.com/overrides/introduction).

#### Resources

##### [GitHub](https://github.com/henrywhitaker3/Speedtest-Tracker)

##### [Docker Hub](https://hub.docker.com/r/henrywhitaker3/speedtest-tracker/tags)
