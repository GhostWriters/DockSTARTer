# Netdata

[![Docker Pulls](https://img.shields.io/docker/pulls/netdata/netdata?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/netdata/netdata)
[![GitHub Stars](https://img.shields.io/github/stars/netdata/netdata?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/netdata/netdata)

## Description

[Netdata](https://www.netdata.cloud/) is distributed, real-time performance and health monitoring for systems and applications. It is a highly-optimized monitoring agent you install on all your systems and containers.

### Changing Netdata's Hostname

By default, Netdata will pull from a UID for the container itself to display in the list of Netdata servers you have, so you would see something like '0f2342dac'. To define this and make it more readable/recognizable for you (In case you have multiple Netdata servers):

- Stop the netdata container.
- Create or edit your [override file](https://dockstarter.com/overrides/introduction/), you can also use [this file](https://gist.github.com/mattgphoto/1e7afc85931ca98002a87abdc8bb257e) for reference.
  - Change `newnetdataname` to `friendlynamefornetdata`.
- Once this is done, run `sudo ds -c netdata`

### Hosting Netdata Behind a Reverse Proxy

For reverse proxy configuration, we'll use this template from guys who already thought of this at [organizrTools](https://github.com/organizrTools).

[Subdomain Template from OrganizrTools](https://github.com/organizrTools/Config-Collections-for-Nginx/blob/master/Apps/netdata.conf)

Subdomain Example:

```nginx
location = /netdata {
    return 301 /netdata/;
}

location ~ /netdata/(?<ndpath>.*) {
    include /config/nginx/proxy.conf;
    resolver 127.0.0.11 valid=30s;
    proxy_redirect off;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Server $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass_request_headers on;
    proxy_set_header Connection "keep-alive";
    proxy_store off;
    proxy_pass http://netdata:19999/$ndpath$is_args$args;
    proxy_headers_hash_max_size 512;
    proxy_headers_hash_bucket_size 64;
    gzip on;
    gzip_proxied any;
    gzip_types *;
}
```

### Notifications

Add [this file](https://github.com/netdata/netdata/blob/master/health/notifications/health_alarm_notify.conf) to your Netdata config directory. Populate the notification service(s) you want with login, tokens, or whichever is appropriate. Instructions can be found in [here](https://github.com/netdata/netdata/blob/master/health/notifications/health_alarm_notify.conf).

Create `health.d` directory in the Netdata config directory. Add `.conf` files from [here](https://github.com/netdata/netdata/tree/master/health/health.d) and select which modules you want alarms for. Also note that one can remove specific alarms by commenting them in the `.conf` files.

#### How To Get CPU Temp From Raspberry Pi

Netdata will not pick up CPU temps by default from a Raspberry Pi. To activate chart for the Pi's CPU temp add a file with name `charts.d.conf` in the Netdata config directory and add the following line.
`sensors=force`

#### How To Get Data From Netdata To HomeAssistant

To identify the correct data group and element to input in netdata home assistant component use `http://yournetdataip:19999/api/v1/allmetrics?format=json`

#### Monitor services with Netdata

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
