# Traefik

[![Docker Pulls](https://img.shields.io/docker/pulls/_/traefik?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/_/traefik)
[![GitHub Stars](https://img.shields.io/github/stars/traefik/traefik-library-image?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/traefik/traefik-library-image)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/.apps/traefik)

## Description

[Traefik](https://doc.traefik.io/traefik/) is a modern HTTP reverse proxy and load balancer that makes deploying microservices easy.

## Install/Setup

This container itself is quite simple but note that lots of customization will be needed for the client apps you will be routing with Traefik. You'll need to use [DockSTARTer overrides](https://dockstarter.com/overrides/introduction/), more specifically editing `docker-compose.override.yml` to add labels, etc, to your client apps to configure Traefik routing.

### traefik.yml

You can configure Traefik itself with a `traefik.yml` file. You should create this at `${DOCKER_VOLUME_CONFIG}/traefik` which is by default volume mapped to `/etc/traefik` inside the container.

## Suggested Reading

[Traefik Documentation](https://doc.traefik.io/traefik/)
[Docker Hub Documentation of Traefik](https://hub.docker.com/_/traefik)
