# Port Conflicts

## Issue/Problem

During configuration the script exits with an error like the following:
> `ERROR: for <appname> cannot start service <appname>: driver failed programming external connectivity on endpoint <appname>
> (5a4d78fd5ff6c4c1a978ef31): Error starting userland proxy: listen udp 0.0.0.0:80: bind: address already in use`
> ERROR: Encountered errors while bringing up the project.
> 2019-02-13 17:38:19 [FATAL]      Docker Compose failed.

This is due to another service that has occupied that port disallowing TrunkSTARTer from installing a service on that port.

## Troubleshooting Methods

As TrunkSTARTer will check and fail if another service is occupying the port, it is necessary to locate and deal with the conflict.

One way is to locate the service currently occupying the port. You can do the following:

```bash
# sudo netstat -ltunp | grep -w ':<port>'
## Example:
sudo netstat -ltunp | grep -w ':80'
```

Once you locate the offending service then you can choose what to do.

## Resolutions/Solutions

One resolution is to change the port being bound during configuration.  During configuration change the external port exposed from _80_ to _8080 (or another unused port)_.  This will resolve the conflict.
