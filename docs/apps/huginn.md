# Huginn

[![Docker Pulls](https://img.shields.io/docker/pulls/huginn/huginn?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/huginn/huginn)
[![GitHub Stars](https://img.shields.io/github/stars/huginn/huginn?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/huginn/huginn)

## Description

Huginn is a system for building agents that perform automated tasks for you online. They can read the web, watch for events, and take actions on your behalf. Huginn's Agents create and consume events, propagating them along a directed graph. Think of it as a hackable version of IFTTT or Zapier on your own server. You always know who has your data. You do.

## Configuration

Huginn is extremely configurable. By default DS only includes variables for the database. The container will run the default variables that are included in their `.env.example` in the container. However, you can pick and choose which [enviroment variables](https://github.com/huginn/huginn/blob/master/.env.example) you want to configure and include them in an [override](https://dockstarter.com/overrides/introduction/).
