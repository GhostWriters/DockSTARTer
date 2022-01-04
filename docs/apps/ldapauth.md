# LDAP-Auth

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/ldap-auth?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/ldap-auth)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-ldap-auth?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-ldap-auth)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/ldapauth)

Ldap-auth software is for authenticating users who request protected resources
from servers proxied by nginx. It includes a daemon (ldap-auth) that
communicates with an authentication server, and a webserver daemon that
generates an authentication cookie based on the user’s credentials. The daemons
are written in Python for use with a Lightweight Directory Access Protocol
(LDAP) authentication server (OpenLDAP or Microsoft Windows Active Directory
2003 and 2012).

## Install/Setup

This application does not have any specific setup instructions documented. If
you need assistance setting up this application please visit our
[support page](https://dockstarter.com/basics/support/).
