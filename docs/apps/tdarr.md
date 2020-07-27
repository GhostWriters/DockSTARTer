# Tdarr

[![Docker Pulls](https://img.shields.io/docker/pulls/haveagitgat/tdarr?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/haveagitgat/tdarr)
[![GitHub Stars](https://img.shields.io/github/stars/haveagitgat/tdarr?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/haveagitgat/tdarr)

## Description

Tdarr is a self hosted web-app for automating media library transcode/remux management and making sure your files are exactly how you need them to be in terms of codecs/streams/containers etc. Designed to work alongside Sonarr/Radarr and built with the aim of modularisation, parallelisation and scalability, each library you add has its own transcode settings, filters and schedule. Workers can be fired up and closed down as necessary, and are split into 3 types - 'general', 'transcode' and 'health check'. Worker limits can be managed by the scheduler as well as manually.
