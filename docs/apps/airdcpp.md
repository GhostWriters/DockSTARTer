# AirDC++

[![Docker Pulls](https://img.shields.io/docker/pulls/gangefors/airdcpp-webclient?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/gangefors/airdcpp-webclient)
[![GitHub Stars](https://img.shields.io/github/stars/gangefors/docker-airdcpp-webclient?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/gangefors/docker-airdcpp-webclient)

## Description

[AirDC++](https://www.airdcpp.net/) is an easy to use client for [Advanced Direct Connect](http://en.wikipedia.org/wiki/Advanced_Direct_Connect)
and [Direct Connect](http://en.wikipedia.org/wiki/Direct_Connect_(file_sharing)) networks. You are able to join "hubs" with other users, and chat, perform searches and browse the share of each user.

### AirDC++ Install

If you see the following error:

> No valid configuration found. Run the application with --configure parameter to set up initial configuration.

Run the following commands to correct:

    docker stop airdcpp

    docker run --rm -it --volumes-from airdcpp gangefors/airdcpp-webclient --add-user

You will be prompted to create a user and password, then run:

    docker start airdcpp
