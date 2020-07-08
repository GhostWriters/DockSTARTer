# Nginx Proxy Manager

[Nginx Proxy Manager](https://nginxproxymanager.com/) is a Docker container for managing Nginx proxy hosts and SSL Certificates with a simple, powerful interface.

The GIT Repository for Nginx Proxy Manager is located at [https://github.com/jc21/nginx-proxy-manager](https://github.com/jc21/nginx-proxy-manager)

## Config File

Nginx Proxy Manager requires a Configuration file named `config.json`. This file needs to be in the appdata folder for NPM before it is started.

```json
{
  "database": {
    "engine": "mysql",
    "host": "db",
    "name": "npm",
    "user": "npm",
    "password": "npm",
    "port": "3306"
  }
}
```

## Example Docker Compose Override

```yaml
version: "3.4"
services:
  proxymanager:
    image: jc21/nginx-proxy-manager:latest
    container_name: proxymanager
    logging:
      driver: json-file
      options:
        max-file: ${DOCKERLOGGING_MAXFILE}
        max-size: ${DOCKERLOGGING_MAXSIZE}

    ports:
      - "80:80"
      - "81:81"
      - "443:443"

    volumes:
      - ${DOCKERCONFDIR}/proxymanager/config.json:/app/config/config.json
      - ${DOCKERCONFDIR}proxymanager/data:/data
      - ${DOCKERCONFDIR}/proxymanager/letsencrypt:/etc/letsencrypt
      - ${DOCKERSHAREDDIR}:/shared
    restart: unless-stopped
```
