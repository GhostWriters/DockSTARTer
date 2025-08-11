# Speedtest

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/speedtest-tracker?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/speedtest-tracker)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-speedtest-tracker?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-speedtest-tracker)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/compose/.apps/speedtest)

## Description

[Speedtest Tracker](https://github.com/linuxserver/docker-speedtest-tracker) is a self-hosted application that monitors the performance and uptime of your internet connection.

### Features

- **Automated Tests**: Schedule regular speed tests to monitor your internet connection's performance over time.
- **Detailed Metrics**: Capture download and upload speeds, ping, packet loss and more.
- **Historical Data**: View historical data and trends to identify patterns and issues with your internet connection.
- **Notifications**: Receive notifications when your internet performance drops below a certain threshold.

## Install/Setup

### Generate an Application Key

Run the command below to generate a key, the key is required for encryption. Copy this key including the base64: prefix and paste it as your `APP_KEY` value in `.env.app.speedtest`.

```bash
echo -n 'base64:'; openssl rand -base64 32;
```

### DB Type

`SQLite` is fine for most installs but you can also use more traditional relational databases like `MariaDB`, `MySQL` and `Postgres`. Update your `DB_CONNECTION` value in `.env.app.speedtest`.

### APP URL

The IP:port or URL your application will be accessed on (ie. http://192.168.1.1:6875 or https://speedtest.mydomain.com). Update your `APP_URL` value in `.env.app.speedtest`.

### Speedtest Servers

A comma-separated list of server IDs to test against. Run the following command to get a list of nearby servers then update your `SPEEDTEST_SERVERS` value in `.env.app.speedtest`.

```bash
docker run -it --rm --entrypoint /bin/bash lscr.io/linuxserver/speedtest-tracker:latest list-servers
```

If you need further assistance setting up this application, please visit the official
[GitHub repository](https://github.com/alexjustesen/speedtest-tracker), [Hub Docker](https://hub.docker.com/r/linuxserver/speedtest-tracker)  or our
[support page](https://dockstarter.com/basics/support).
