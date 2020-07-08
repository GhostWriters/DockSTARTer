# Home Assistant

[Home Assistant](https://www.home-assistant.io/) is a home automation platform running on Python 3 that puts local control and privacy first. It is able to track and control all devices at home and offer a platform for automating control. Powered by a worldwide community of tinkerers and DIY enthusiasts. Perfect to run on a Raspberry Pi or a local server.

The GIT Repository for Home Assistant is located at [https://github.com/home-assistant/home-assistant](https://github.com/home-assistant/home-assistant).

## Environment Variable

You may want to override `homeassistant` with environment variable `PYTHONWARNINGS="ignore:Unverified HTTPS request"` if you recevieve warning each 10 second for e.g. device tracking of self-signed Unifi Controller SSL certificated.

Reference: [https://community.home-assistant.io/t/endless-insecurerequestwarning-errors-with-unifi/31831/12](https://community.home-assistant.io/t/endless-insecurerequestwarning-errors-with-unifi/31831/12)
