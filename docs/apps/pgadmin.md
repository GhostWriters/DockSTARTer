# pgAdmin

[![Docker Pulls](https://img.shields.io/docker/pulls/dpage/pgadmin4?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/dpage/pgadmin4)
[![GitHub Stars](https://img.shields.io/github/stars/pgadmin-org/pgadmin4?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/pgadmin-org/pgadmin4)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/pgadmin)

## Description

[pgAdmin](https://www.pgadmin.org/): pgAdmin is the most popular and feature rich Open Source administration and development platform for PostgreSQL, the most advanced Open Source database in the world.

## Install/Setup

An email address (login) and password are the only required inputs for a fullly functional instance of pgAdmin.

Full variable documentation is available in the pgadmin [documentation](https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html#environment-variables).

Any variable name from [config.py](https://www.pgadmin.org/docs/pgadmin4/latest/config_py.html#config-py) can be defined in the format of `PGADMIN_CONFIG_*` in docker-compose.override.yml
