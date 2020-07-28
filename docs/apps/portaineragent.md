# Portainer Agent

[![Docker Pulls](https://img.shields.io/docker/pulls/portainer/agent?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/portainer/portainer)
[![GitHub Stars](https://img.shields.io/github/stars/portainer/agent?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/portainer/agent)

## Description

The purpose of the agent is to work around a Docker API limitation. When using the Docker API to manage a Docker environment, the user interactions with specific resources (containers, networks, volumes and images) are limited to these available on the node targeted by the Docker API request.

Docker Swarm mode introduces the concept of cluster of Docker nodes. With that concept, it also introduces the services, tasks, configs and secrets which are cluster aware resources. This means that you can query for the list of service or inspect a task inside any node on the cluster as long as you're executing the Docker API request on a manager node.

Containers, networks, volumes and images are node specific resources, not cluster aware. If you want to get the list of all the volumes available on the node number 3 inside your cluster, you need to execute the request to query the volumes on that specific node.

The agent purpose aims to solve that issue and make the containers, networks and volumes resources cluster aware while keeping the Docker API request format.

This means that you only need to execute one Docker API request to retrieve all the volumes inside your cluster for example.

The final goal is to bring a better Docker UX when managing Swarm clusters.
