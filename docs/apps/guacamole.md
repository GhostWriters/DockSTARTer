# Guacamole

This guide will help you replicate Gilbn's tutorial to protect your Guacamole install with F2B

Since DockSTARTer uses Oznu's image for Guacamole, it only generates logs inside the container itself. Following these steps will allow you to get the Guacamole container to generate a log file in `~/.config/appdata/guacamole` which you can then mount to the LetsEncrypt container so F2B can monitor it and ban malicious IPs.

You can find Gilbn's tutorial [here](https://technicalramblings.com/blog/remotely-accessing-the-unraid-gui-with-guacamole-and-vnc-web-browser/). We recommend you read it over so you get a basic understanding of what you will be doing:

## Configuring Guacamole

1. Create a `logback.xml` file inside `~/.config/appdata/guacamole/guacamole`
    * `touch ~/.config/appdata/guacamole/guacamole/logback.xml`
          or
    * `sudo nano ~/.config/appdata/guacamole/guacamole/logback.xml`
1. Open the file with your favorite editor and place the following contents inside of it:

    **NOTE: Make sure to make changes to the timezone accordingly. Check the `php-local.ini` file in `~/.config/appdata/letsencrypt/php` if you are not sure what your timezone is.**

```xml
<configuration>
    <!-- Appender for debugging -->
    <appender name="GUAC-DEBUG" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{HH:mm:ss.SSS, America/New_York} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    <!-- Appender for debugging in a file-->
    <appender name="GUAC-DEBUG_FILE" class="ch.qos.logback.core.FileAppender">
        <file>/config/logs/guacd.log</file>
        <encoder>
            <pattern>%d{HH:mm:ss.SSS, America/New_York} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    <!-- Log at DEBUG level -->
    <root level="debug">
        <appender-ref ref="GUAC-DEBUG"/>
        <appender-ref ref="GUAC-DEBUG_FILE"/>
    </root>
</configuration>
```

1. Restart the Guacamole container so it creates `guacd.log` in `~/.config/appdata/guacamole/logs/`
2. Modify your docker-compose.override.yml in `~/.docker/compose/docker-compose.override.yml` file to mount the new log to letsencrypt

Example:

```yaml
  letsencrypt:
    volumes:
      - ${DOCKERCONFDIR}/guacamole/logs/:/var/log/guacamole/
```

   **NOTE: From here on out, we will be using `/var/log/guacamole` to refer to where the guacd.log lives within letsencrypt. This is just an example, you can mount your log file wherever you want inside the letsencrypt container.

1. Recreate your container by running `ds -c up`
1. Perform an invalid login attempt on Guacamole
1. Check the new guacd.log file located in `~/.config/appdata/guacamole/logs` to verify the failed login attempt

Example:

```bash
grep -i nzbget ~/.config/appdata/guacamole/logs/guacd.log | grep failed
15:03:17.762 [http-nio-8080-exec-1] WARN  o.a.g.r.auth.AuthenticationService - Authentication attempt from [x.x.x.x, x.x.x.x, x.x.x.x]
for user "nzbget" failed.
```

## Configuring F2B

1. Navigate to `~/.config/appdata/letsencrypt/fail2ban`, in there you will see (2) folders `action.d` and `filter.d`, as well as other files, we are going to focus on the file called `jail.local` for now.
2. Go ahead and open `jail.local` with your favorite editor as root and copy/paste the following:

```ini
[guacamole-auth]

enabled = true
port = http,https
filter = guacamole-auth
logpath = /var/log/guacamole/guacd.log
ignoreip = 192.168.1.0/24
```

**NOTE: The ignore IP is so that fail2ban won’t ban your local IP. Check out [https://www.aelius.com/njh/subnet_sheet.html](https://www.aelius.com/njh/subnet_sheet.html) if you are wondering what your CIDR notation is. Most often it will be /24 (netmask 255.255.255.0)
To find your netmask run `ipconfig /all` on windows or `ifconfig | grep netmask` on linux.

1. Next we are going to navigate to `~/.config/appdata/letsencrypt/fail2ban/filter.d` and in there you will see a file called `guacamole.conf`. We can't use this file because the regex in there will not work for our purposes.
1. Open `guacamole.conf` with your favorite text editor as root and modify the regex line called `failregex` to match this:
   * `\bAuthentication attempt from <HOST> for user "[^"]*" failed\.$`
1. Next save the file and name it `guacamole-auth.conf`
1. Perform an invalid login attempt and check fail2ban's regex for Guacamole with the following command:
   * `docker exec -it letsencrypt fail2ban-regex /var/log/guacamole/guacd.log /config/fail2ban/filter.d/guacamole-auth.conf`
1. If you want to ban yourself, you can comment out the `ignoreip` line on `jail.local`.

BONUS: Want to see notifications when someone gets the hammer? Check out this cool [Discord guide](https://technicalramblings.com/blog/adding-ban-unban-notifications-from-fail2ban-to-discord/) or this [Pushover guide](https://technicalramblings.com/blog/adding-ban-unban-notifications-from-fail2ban-with-pushover/)

Credits @halianelf, @christronyxyocum, @gilbN and @iXNyNe
