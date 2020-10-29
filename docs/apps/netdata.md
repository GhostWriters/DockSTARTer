# Netdata

[![Docker Pulls](https://img.shields.io/docker/pulls/netdata/netdata?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/netdata/netdata)
[![GitHub Stars](https://img.shields.io/github/stars/netdata/netdata?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/netdata/netdata)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/netdata)

## Description

[Netdata](https://www.netdata.cloud/) is distributed, real-time performance and health monitoring for systems and applications. It is a highly-optimized monitoring agent you install on all your systems and containers.

## Install/Setup

### Changing Netdata's Hostname

By default, Netdata will pull from a UID for the container itself to display in the list of Netdata servers you have, so you would see something like '0f2342dac'. To define this and make it more readable/recognizable for you (In case you have multiple Netdata servers):

- Stop the netdata container.
- Create or edit your [override file](https://dockstarter.com/overrides/introduction/)

  ```yaml
  services:
    netdata:
      hostname: newnetdataname
  version: "3.4"
  ```

- Once this is done, run `sudo ds -c netdata`

### Notifications

Add [this file](https://github.com/netdata/netdata/blob/master/health/notifications/health_alarm_notify.conf) to your Netdata config directory. Populate the notification service(s) you want with login, tokens, or whichever is appropriate. Instructions can be found in [here](https://github.com/netdata/netdata/blob/master/health/notifications/health_alarm_notify.conf).

Create `health.d` directory in the Netdata config directory. Add `.conf` files from [here](https://github.com/netdata/netdata/tree/master/health/health.d) and select which modules you want alarms for. Also note that one can remove specific alarms by commenting them in the `.conf` files.

### How To Get CPU Temp From Raspberry Pi

Netdata will not pick up CPU temps by default from a Raspberry Pi. To activate chart for the Pi's CPU temp add a file with name `charts.d.conf` in the Netdata config directory and add the following line.
`sensors=force`

### How To Get Data From Netdata To HomeAssistant

To identify the correct data group and element to input in netdata home assistant component use `http://yournetdataip:19999/api/v1/allmetrics?format=json`

### Monitor services with Netdata

Create python.d directory in Netdata config directory. Add [this file](https://github.com/netdata/netdata/blob/master/health/health.d/httpcheck.conf) to your python.d directory. Edit according to instructions in file. Our suggestion is to add after the last line in the `.conf` file. See example below:

```conf
# This plugin is intended for simple cases. Currently, the accuracy of the response time is low and should be used as reference only.

Hydra:
    url: 'http://192.168.86.60:5076/nzbhydra/'
    timeout: 1
    redirect: no
    status_accepted:
        - 200
    regex: '.*hydra.*'

Ombi:
    url: 'http://192.168.86.60:3579/ombi/landingpage'
    timeout: 1
    redirect: yes
    status_accepted:
        - 200
    regex: '.*ombi.*'
```

You will now get charts in Netdata for Ombi and NZBHydra. Please add your IP and ports accordingly.

To get alarms add [this file](https://github.com/netdata/netdata/blob/master/health/health.d/httpcheck.conf) to your health.d directory. Don't forget to comment the unwanted alarms. Slow response alarms can be quite annoying.
