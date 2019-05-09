---
layout: default
---

Logarr configuration has sharing to the logs enabled by default. From within the Logarr container, this is accessible via the `/var/log/logarrlogs` path. Which is mapped to your `~/.config/appdata` path of your host machine.

For Logarr you will need to edit the `config.php` file to point to the correct log files. This file is located in the `~/.config/appdata/logarr/www/logarr/assets/` folder of your host machine.


Edit the included config to change these lines:
```
    "Sonarr" => '/var/log/logarrlogs//sonarr/logs/sonarr.txt',

    "Radarr" => '/var/log/logarrlogs/radarr/logs/radarr.txt',

```
