# Synapse

[![Docker Pulls](https://img.shields.io/docker/pulls/matrixdotorg/synapse/?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/matrixdotorg/synapse)
[![GitHub Stars](https://img.shields.io/github/stars/matrix-org/synapse?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/matrix-org/synapse)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/synapse)

## Description

[Synapse](https://github.com/matrix-org/synapse) is a matrix homeserver written in Python 3/Twisted.

## Install/Setup

### Generating an (admin) user

After synapse is running, you may wish to create a user via ``register_new_matrix_user``.
This requires a ``registration_shared_secret`` to be set in your config file. Synapse must be restarted to pick up this change.
You can then call the script:

```
docker exec -it synapse register_new_matrix_user http://localhost:8008 -c /data/homeserver.yaml --help
```

Remember to remove the ``registration_shared_secret`` and restart if you no-longer need it.

