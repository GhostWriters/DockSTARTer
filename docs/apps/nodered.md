# Node-RED

[![Docker Pulls](https://img.shields.io/docker/pulls/nodered/node-red?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/nodered/node-red)
[![GitHub Stars](https://img.shields.io/github/stars/node-red/node-red-docker?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/node-red/node-red-docker)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/nodered)

## Description

[Node-RED](https://nodered.org/)  is a programming tool for wiring together hardware devices, APIs and online services in new and interesting ways.

It provides a browser-based editor that makes it easy to wire together flows using the wide range of nodes in the palette that can be deployed to its runtime in a single-click.

## Install/Setup

This application does not have any specific setup instructions documented. If you need assistance setting up this application please visit our [support page](https://dockstarter.com/basics/support/).

## Common Issues

When you first spin up Node-RED, check your container logs `docker logs nodered` and you might see something like this:

```bash
> node-red-docker@1.2.6 start /usr/src/node-red
> node $NODE_OPTIONS node_modules/node-red/red.js $FLOWS "--userDir" "/data"

fs.js:114
    throw err;
    ^

Error: EACCES: permission denied, copyfile '/usr/src/node-red/node_modules/node-red/settings.js' -> '/data/settings.js'
    at Object.copyFileSync (fs.js:1728:3)
    at copyFile (/usr/src/node-red/node_modules/fs-extra/lib/copy-sync/copy-sync.js:68:8)
    at onFile (/usr/src/node-red/node_modules/fs-extra/lib/copy-sync/copy-sync.js:53:25)
    at getStats (/usr/src/node-red/node_modules/fs-extra/lib/copy-sync/copy-sync.js:48:44)
    at startCopy (/usr/src/node-red/node_modules/fs-extra/lib/copy-sync/copy-sync.js:38:10)
    at handleFilterAndCopy (/usr/src/node-red/node_modules/fs-extra/lib/copy-sync/copy-sync.js:33:10)
    at Object.copySync (/usr/src/node-red/node_modules/fs-extra/lib/copy-sync/copy-sync.js:26:10)
    at Object.<anonymous> (/usr/src/node-red/node_modules/node-red/red.js:125:20)
    at Module._compile (internal/modules/cjs/loader.js:778:30)
    at Object.Module._extensions..js (internal/modules/cjs/loader.js:789:10)
npm ERR! code ELIFECYCLE
npm ERR! errno 1
npm ERR! node-red-docker@1.2.6 start: `node $NODE_OPTIONS node_modules/node-red/red.js $FLOWS "--userDir" "/data"`
npm ERR! Exit status 1
npm ERR!
npm ERR! Failed at the node-red-docker@1.2.6 start script.
npm ERR! This is probably not a problem with npm. There is likely additional logging output above.
```

This can be resolved by fixing the permissions on the appdata folder, just run:

```bash
sudo chown $USER:$GROUP -R ~/.config/appdata/nodered
```
