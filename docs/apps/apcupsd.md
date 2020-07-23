# Apcupsd

[![Docker Pulls](https://img.shields.io/docker/pulls/atribe/apcupsd-influxdb-exporter?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/atribe/apcupsd-influxdb-exporter)
[![GitHub Stars](https://img.shields.io/github/stars/atribe/apcupsd-influxdb-exporter?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/atribe/apcupsd-influxdb-exporter)

## Description

Apcupsd is a dockerized Python script that will send data from [apcupsd](http://www.apcupsd.org/) to influxdb. You can then visualize the influxdb data in [Grafana](https://grafana.com/)/[Prometheus](https://prometheus.io/).

First you need to install `apcupsd` on your host. The command will vary depending on what Linux OS you are using. After you install `apcupsd` on your host, there are some changes that need to take place in your `apcupsd.conf` file. Again, the location of this file varies by OS, however, for Ubuntu based systems you can find this file in `/etc/apcupsd/`.

By default `acpupsd` it is set to listen on `127.0.0.1`. DockSTARTer (DS) does not run containers on `host` mode so your container will not be able to communicate with your `apcupsd` service. You need to open the `apcupsd.conf` file and search for `NISIP`. You need to change the IP address listed there to your local IP. Once you do this, you need to restart your `apcupsd` service so new settings take place.

The docker image DS uses makes uses of `NOMPOWER` on your UPS. If your UPS **does not have** `NOMPOWER`, you will need to add an [override](https://dockstarter.com/overrides/introduction/) to your existing DS installation and set a new environment variable called `WATTS` under `environment` which will need to equal the rated max power for your UPS, e.g: `1000`. To find whether your UPS has `NOMPOWER` or not, you can run `apcaccess | grep "NOMPOWER"`.

[Here](https://web.archive.org/web/20190819132348/https://technicalramblings.com/blog/monitoring-your-ups-stats-and-cost-with-influxdb-and-grafana-on-unraid-2019-edition/) is a great guide for exporting the influxdb data to Grafana. Just scroll down to the `UPS Dashboard` bit.
