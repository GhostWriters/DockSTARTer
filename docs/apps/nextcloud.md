---
layout: default
---

If you are running the DockSTARTer Nextcloud container behind a LetsEncrypt Reverse gateway, you may need to add a extra line to the NextCloud config.php file so it can find it.

you will be able to access the web page all OK, but any apps may timeout or return an invalid password

run the below command and add the line to the the config.php file before the );

```
nano /config/www/nextcloud/config/config.php

'overwritehost' => 'hostname',
```
where your 'hostname' is the URL you use to access your NextCloud web interface, make sure you include the comma at the end.

this will allow the apps to pass the username/password through to the application
