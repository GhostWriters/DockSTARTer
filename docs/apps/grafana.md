# Grafana

## Fix for permission problems

If you see the following error:

```
mkdir: cannot create directory '/var/lib/grafana/plugins': Permission denied,
GF_PATHS_DATA='/var/lib/grafana' is not writable.
```

Run the following command to fix it:

`sudo chown -R $USER:$USER ~/.config/appdata/grafana`

Where UID and GID is the one configured on DockSTARTer, and Grafana's appdata folder is DockSTARTer's appdata folder appended with /grafana/ (e.g.: /home/username/.config/appdata/grafana/).

## Checking your variables

If you don't know the variables needed above, is rather simple to check:

1. Run DockSTARTer (`sudo ds`)
1. Chooses `Configuration`
1. Select `Set Global Variables`
1. Your DockSTARTer variables will be displayed, you're looking for the `PUID=`, `PGID=` and `DOCKERCONFDIR=`values.

> `PUID` is UID;
>
> `PGID` is GID;
>
> `DOCKERCONFDIR` is DS' appdata folder, just append `/grafana/` to get Grafana's appdata folder.
