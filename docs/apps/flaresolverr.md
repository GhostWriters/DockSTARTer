# FlareSolverr

[![Docker Pulls](https://img.shields.io/docker/pulls/flaresolverr/flaresolverr?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/flaresolverr/flaresolverr)
[![GitHub Stars](https://img.shields.io/github/stars/FlareSolverr/FlareSolverr?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/FlareSolverr/FlareSolverr)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/main/.apps/flaresolverr)

## Description

FlareSolverr starts a proxy server and it waits for user requests in an idle
state using few resources. When some request arrives, it uses puppeteer with the
stealth plugin to create a headless browser (Chrome). It opens the URL with user
parameters and waits until the Cloudflare challenge is solved (or timeout). The
HTML code and the cookies are sent back to the user, and those cookies can be
used to bypass Cloudflare using other HTTP clients.

## Install/Setup
