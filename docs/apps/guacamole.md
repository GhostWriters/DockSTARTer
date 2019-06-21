# This guide will help you follow Gilbn's tutorial to protect your Guacamole install with F2B.

Since DockSTARTer uses Oznu's image for Guacamole, it only generates logs inside the container itself. Following these steps will allow you to get the Guacamole container to generate a log file in `~/.config/appdata/guacamole` which you can then mount to the LetsEncrypt container so F2B can monitor it and ban malicious IPs.

You can find Gilbn's tutorial [here](https://technicalramblings.com/blog/remotely-accessing-the-unraid-gui-with-guacamole-and-vnc-web-browser/). You will need to follow it after completing the following steps:

1. Create a `logback.xml` file inside `~/.config/appdata/guacamole/guacamole`
    * `touch ~/.config/appdata/guacamole/guacamole`
            
          or
            
    * `sudo nano ~/.config/appdata/guacamole/guacamole/logback.xml`
1. Open the file with your favorite editor and place the following contents inside of it: 


    **NOTE: Make sure to make changes to the timezone accordingly. Check the `php-local.ini` file in `~/.config/appdata/letsencrypt/php` if you are not sure what your timezone is.** 

 ```
 <configuration>
        <!-- Appender for debugging -->
        <appender name="GUAC-DEBUG" class="ch.qos.logback.core.ConsoleAppender">
                <encoder>
                        <pattern>%d{HH:mm:ss.SSS, America/New_York} [%thread] %-5level %logger{36} - %msg%n</pattern>
                </encoder>
        </appender>
        <!-- Appender for debugging in a file-->
        <appender name="GUAC-DEBUG_FILE" class="ch.qos.logback.core.FileAppender">
                <file>/usr/local/tomcat/logs/guacd.log</file>
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
3. Restart the Guacamole container so it creates the /usr/local/tomcat/logs/guacd.log file inside of the container.
1. Create an empty, corresponding file in the Guacamole appdata dir: 
    1. touch `~/.config/appdata/guacamole/guacd.log`
1. Modify your docker-compose.override.yml in `~/.docker/compose/docker-compose.override.yml` file to mount the new log to LetsEncrypt
    1. Example: 
    ```
    letsencrypt:
    volumes:
      - ${DOCKERCONFDIR}/guacamole:/var/log/guacamole
     ```
6. Recreate your container by running `ds -c up`
1. Perform an invalid login attempt on Guacamole
1. Check the new guacd.log file located in `~/.config/appdata/guacamole` to verify the failed login attempt
    1. Example: 
    ```
    grep -i nzbget /home/guacamole/config/guacamole/guacd.log | grep failed 
    15:03:17.762 [http-nio-8080-exec-1] WARN  o.a.g.r.auth.AuthenticationService - Authentication attempt from [x.x.x.x, x.x.x.x, x.x.x.x]
    for user "nzbget" failed.
    ```
9. Follow Gilbn's guide, which again can be located [here](https://technicalramblings.com/blog/remotely-accessing-the-unraid-gui-with-guacamole-and-vnc-web-browser/).

Your regex might need some tweaking, you can try the one Gilbn suggests or you can try this one:
  * `\bAuthentication attempt from <HOST> for user "[^"]*" failed\.$`

10. Perform an invalid login attempt and check fail2ban's regex for Guacamole with the following command: 
  `docker exec -it letsencrypt fail2ban-regex /var/log/guacamole/guacd.log /config/fail2ban/filter.d/guacamole-auth.conf`


Credits @halianelf, @christronyxyocum and @gilbN
