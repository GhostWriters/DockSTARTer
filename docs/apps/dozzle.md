# Dozzle

Dozzle is a simple, lightweight application that provides you with a web based interface to monitor your Docker container logs live. It doesn’t store log information, it is for live monitoring of your container logs only.

**Dozzle doesn't support authentication out of the box.**

## Changing Dozzle's base URL

Dozzle by default mounts to `/`. If you want to control the base path you will need to use an [override](https://dockstarter.com/overrides/introduction/) and add the environment variable `DOZZLE_BASE`. **We do not recommend you expose dozzle to the outside world without some sort of protection in front of it such as [Organizr's Server Auth](https://docs.organizr.app/books/setup-features/page/serverauth).
