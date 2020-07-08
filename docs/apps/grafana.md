# Grafana

[Grafana](https://grafana.com/) is an open-source platform for monitoring and observability. Grafana allows you to query, visualize, alert on and understand your metrics no matter where they are stored. Create, explore, and share dashboards with your team and foster a data driven culture.

The GIT Repository for Grafana is located at [https://github.com/grafana/grafana](https://github.com/grafana/grafana/docker-goaccess).

## Fix for permission problems

If you see the following error:

```log
mkdir: cannot create directory '/var/lib/grafana/plugins': Permission denied,
GF_PATHS_DATA='/var/lib/grafana' is not writable.
```

Run the following command to fix it:

`sudo chown -R $USER:$USER ~/.config/appdata/grafana`
