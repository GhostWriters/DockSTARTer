# Backups

## THIS IS DEPRECATED AND REMOVED FROM DOCKSTARTER AS OF 01/01/2020

## Creating backups

DockSTARTer menu has an option for `Backup Config`, or you can use one of `ds -b min` / `ds -b med` / `ds -b max` to create backups.

> Min: Backs up your .env file
> Med: Backs up your .env file and the config folder for any enabled app
> Max: Backs up your .env file and any config folder found in your DOCKER_VOLUME_CONFIG. Apps will be stopped before running a backup and started after completing a backup.

Med and Max also support pre/post commands in between each app (so you could disable uptime monitors for example)
Min, Med, and Max support pre/post commands for the entire run. These commands can be set in `.env`

## Scheduling backups

It is recommended to setup a cron job using `sudo crontab -e` and adding a line like

```bash
0 2 * * * /home/<USER>/.docker/main.sh -b min
```

or

```bash
0 2 * * * /home/<USER>/.docker/main.sh -b med
```

or

```bash
0 2 * * * /home/<USER>/.docker/main.sh -b max
```

Which would make a daily backup at 2 AM.

## Backup retention

The snapshot backup is created into `${BACKUP_CONFDIR}/<appname>.001`. If the folder `<appname>.001` exists already it is rotated to `<appname>.002` and so on, up to `<appname>.512` by default (this can be adjusted), thereafter it is removed. So if you create one backup per night, for example with a cronjob, then this retention policy gives you 512 days of retention. This is useful but this can require to much disk space, that is why we have included a non-linear distribution policy. In short, we keep only the oldest backup in the range 257-512, and also in the range 129-256, and so on. This exponential distribution in time of the backups retains more backups in the short term and less in the long term; it keeps only 10 or 11 backups but spans a retention of 257-512 days.
In the following table you can see on each column the different steps of the rotation, where each column shows the current set of snapshots (limited from `<appname>.1` to `<appname>.16` in this example):

```bash
1   1   1   1   1   1   1   1   1   1   1   1   1   1   1   1   1
2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2
    3       3       3       3       3       3       3       3
4       4       4       4       4       4       4       4       4
    5               5               5               5
        6               6               6               6
            7               7               7               7
8               8               8               8               8
    9                               9
        10                              10
            11                              11
                12                              12
                    13                              13
                        14                              14
                            15                              15
16                              16                              16
```

To save more disk space, `rsync` will make hard links for each file of `<appname>.001` that already existed in `<appname>.002` with identical content, timestamps and ownerships.

## Deleting backups

Backups created by DockSTARTer will be protected with a special attribute called `immutable` that makes the backups read only to all users including root. This is done to protect your backups from accidental deletion. Backups will be rotated through retention as described above because the backup script handles the immutable attribute. If you need to delete a backup manually you will first need to remove the immutable attribute from the folder using `sudo chattr -R -i /path/to/backup/<appname>.###`

## Credits

The backup function is strongly borrowed from [http://www.pointsoftware.ch/en/howto-local-and-remote-snapshot-backup-using-rsync-with-hard-links/](http://www.pointsoftware.ch/en/howto-local-and-remote-snapshot-backup-using-rsync-with-hard-links/) which has sections explaining how the `rsync` process works, including information about hard links (backups don't take up as much space as you think!)
