---
layout: default
---

# Issue/Problem:

During configuration the script exits with an error like the following:

  `ERROR: for plex  Cannot start service plex: driver failed programming external connectivity on endpoint plex
  (5a4d78fd5ff6c4c1a978ef31): Error starting userland proxy: listen udp 0.0.0.0:5353: bind: address already in use`
  `ERROR: Encountered errors while bringing up the project.`
  `2019-02-13 17:38:19 [FATAL]      Docker Compose failed.`

This is due to another service that has occupied that port disallowing DockSTARTer from installing a service on that port.


# Troubleshooting Methods:

As DockSTARTer will check and fail if another service is occupying the port, it is necessary to locate and deal with the conflict.

One way is to locate the service currently occupying the port. You can do the following:

  _`sudo netstat -ltunp | grep -w ':<port>'`    example: `sudo netstat -ltunp | grep -w ':8080'`_

Once you locate the offending service then you can choose what to do.


# Resolutions/Solutions:

**Example:** If you have avahi-daemon installed this will conflict with _udp/5353_ port usage for iTunes in Plex if selected.  This will cause the script to exit with an [ERROR] and a [FATAL].   

One resolution is to change the port being bound during configuration.  During configuration change the external port exposed from _5353_ to _5354 (or another unused port)_.  This will resolve the conflict.

Another resolution would be to remove the software that is in conflict.  Again as the example above.  If you are not using mDNS resolution then avahi-daemon would be unnecessary. Simply remove the package with _`apt remove avahi-daemon`_ from the base server. This will remove the offending service and allow the port to be used by the Docker service.
