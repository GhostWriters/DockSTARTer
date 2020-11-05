# Duplicacy

[![Docker Pulls](https://img.shields.io/docker/pulls/saspus/duplicacy-web?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/saspus/duplicacy-web)
[![Bitbucket Repo](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=bitbucket&message=repo)](https://bitbucket.org/saspus/duplicacy-web-docker-container/)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/duplicacy)

## Description

[Duplicacy](https://duplicacy.com/) is built on top of a new idea called Lock-Free Deduplication, which works by relying on the basic file system API to manage deduplicated chunks without using any locks. A two-step fossil collection algorithm is devised to solve the fundamental problem of deleting unreferenced chunks under the lock-free condition, making deletion of old backups possible without using a centralized chunk database.
