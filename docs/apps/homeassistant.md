# Home Assistant

[![Docker Pulls](https://img.shields.io/docker/pulls/homeassistant/home-assistant?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/homeassistant/home-assistant)
[![GitHub Stars](https://img.shields.io/github/stars/home-assistant/core?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/home-assistant/core)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/homeassistant)

## Description

[Home Assistant](https://www.home-assistant.io/) is a home automation platform running on Python 3 that puts local control and privacy first. It is able to track and control all devices at home and offer a platform for automating control. Powered by a worldwide community of tinkerers and DIY enthusiasts. Perfect to run on a Raspberry Pi or a local server.

## Install/Setup

This application does not have any specific setup instructions documented. If you need assistance setting up this application please visit our [support page](https://dockstarter.com/basics/support/).

### Suggestions

You may want to create an [override](https://dockstarter.com/overrides/introduction/) for `homeassistant` with the following if you are receiving a warning every 10 seconds for:
>device tracking of self-signed Unifi Controller SSL certificated.

``` yml
        environment:
            - PYTHONWARNINGS="ignore:Unverified HTTPS request"
```

Reference: [Endless InsecureRequestWarning errors with UniFi](https://community.home-assistant.io/t/endless-insecurerequestwarning-errors-with-unifi/31831/12)
