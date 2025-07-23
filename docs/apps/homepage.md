# Homepage

[![Image Size](https://ghcr-badge.egpl.dev/gethomepage/homepage/size?color=%2344cc11&tag=latest&label=image+size&trim=)](https://github.com/gethomepage/homepage/pkgs/container/homepage)
[![GitHub Stars](https://img.shields.io/github/stars/gethomepage/homepage?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/gethomepage/Homepage)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/compose/.apps/homepage)

## Description

[Homepage](https://github.com/gethomepage/Homepage) is a modern, fully static, fast, secure fully proxied, highly customizable application dashboard with integrations for over 100 services and translations into multiple languages. Easily configured via YAML files or through docker label discovery. .

## Install/Setup

Refer to the following pages for detailed instructions:

- [Homepage Docker Installation](https://gethomepage.dev/latest/installation/docker/)
- [Homepage Configs](https://gethomepage.dev/latest/configs/)

Docker integration is enabled in the setting label by default, you can disable by remove the `HOMEPAGE_DOCKER_INTERGRATE` environment variable.

### Using Environment Secrets

#### You can also include environment variables in your config files to protect sensitive information

Note:

- Environment variables must start with HOMEPAGE*VAR* or HOMEPAGE*FILE*
- The value of env var HOMEPAGE_VAR_XXX will replace {{HOMEPAGE_VAR_XXX}} in any config
- The value of env var HOMEPAGE_FILE_XXX must be a file path, the contents of which will be used to replace {{HOMEPAGE_FILE_XXX}} in any config
