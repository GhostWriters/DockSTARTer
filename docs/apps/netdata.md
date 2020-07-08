# netdata

By default, netdata will pull from a UID for the container itself to display in the list of netdata servers you have, so you would see something like '0f2342dac'. To define this and make it more readable/recognizable for you (In case you have multiple netdata servers):

1. Stop the netdata container.
1. Edit or Create this file: [~/.docker/compose/docker-compose.override.yml](https://gist.github.com/mattgphoto/1e7afc85931ca98002a87abdc8bb257e) and change `newnetdataname` to `friendlynamefornetdata`.
1. Once this is done, re-run `sudo ds -c`

For Reverse Proxy configuration, we'll use this template from guys who already thought of this at [organizrTools](https://github.com/organizrTools).

[Template from OrganizrTools](https://github.com/organizrTools/Config-Collections-for-Nginx/blob/master/Apps/netdata.conf)

Example:

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

## Notifications

Add [health_alarm_notify.conf](https://github.com/netdata/netdata/blob/master/health/notifications/health_alarm_notify.conf) to your netdata config directory. Populate the notification service(s) you want with login, tokens or similar that is applicable. Instructions found in [health_alarm_notify.conf](https://github.com/netdata/netdata/blob/master/health/notifications/health_alarm_notify.conf).

Create health.d directory in netdata config directory. Add conf files from [health.d](https://github.com/netdata/netdata/tree/master/health/health.d) for which modules you want alarms. Also note that one can remove specific alarms by commenting them in .conf files.

## Get CPU temp from raspberry pi

Netdata will not pick up cpu temp per default for raspberry pi. To activate chart for pi cpu temp add a file with name charts.d.conf in netdata config directory and add the following line.
`sensors=force`

## Get data for home assistant

To identify the correct data group and element to input in netdata home assistant component use <http://yournetdataip:19999/api/v1/allmetrics?format=json>

## Monitor services with netdata

Create python.d directory in netdata config directory. Add [httpcheck.conf](https://github.com/netdata/netdata/blob/master/health/health.d/httpcheck.conf) to your python.d directory. Edit according to instructions in file, suggestion is to add after last line in conf file. See example below.

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

You will now get charts in netdata for ombi and hydra. Please add your ip and ports accordingly.

To get alarms add [httpcheck.conf](https://github.com/netdata/netdata/blob/master/health/health.d/httpcheck.conf) to your health.d directory. Don't forget to comment the unwanted alarms. Slow response alarm can be quite annoying.

## Netdata badges

Coming soon.
