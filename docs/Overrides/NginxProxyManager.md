# Nginx Proxy Manager

[Nginx Proxy Manager](https://[https://nginxproxymanager.com/](https://nginxproxymanager.com/))  is  Docker container for managing Nginx proxy hosts and SSL Certificates with a simple, powerful interface.
 
# Features of Nginx Proxy Manager
 
### Get Connected
Expose web services on your network · Free SSL with Let's Encrypt · Designed with security in mind · Perfect for home networks

### Proxy Hosts
Expose your private network Web services and get connected anywhere.

### Beautiful UI
Based on Tabler, the interface is a pleasure to use. Configuring a server has never been so fun.

### Free SSL
Built in Let’s Encrypt support allows you to secure your Web services at no cost to you. The certificates even renew themselves!

### Multiple Users
Configure other users to either view or manage their own hosts. Full access permissions are available.

The GIT Repository for Nginx Proxy Manager is located at [[https://github.com/jc21/nginx-proxy-manager](https://github.com/jc21/nginx-proxy-manager)

## Example Docker Compose Override

####NGINX Proxy Manager with LetsEncrypt https://github.com/jc21/nginx-proxy-manager
    
version: "3.4" # this must match the version in docker-compose.yml
services:
   proxymanager:
   image: jc21/nginx-proxy-manager:latest
   container_name: proxymanager
   labels:
	    - "com.dockstarter.appinfo.description: NGINX Proxy Manager with LetsEncrypt included"
    - "com.dockstarter.appinfo.nicename: NGINX Proxy Manager"
    
    logging:
    
    driver: json-file
    
    options:
    
    max-file: ${DOCKERLOGGING_MAXFILE}
    
    max-size: ${DOCKERLOGGING_MAXSIZE}
    
    ports:
    
    - "80:80"
    
    - "81:81"
    
    - "443:443"
    
    environment:
    
    - FORCE_COLOR=1
    
    - NODE_ENV=config
    
    volumes:
    
    - /opt/appdata/proxymanager/config.json:/app/config/config.json
    
    - /opt/appdata/proxymanager/data:/data
    
    - /opt/appdata/proxymanager/letsencrypt:/etc/letsencrypt
    
    - ${DOCKERSHAREDDIR}:/shared
    
    depends_on:
    
    - mariadb
    
    restart: unless-stopped
    
    mariadb:
    
    container_name: mariadb
    
    image: mariadb:latest
    
    labels:
    
    - "com.dockstarter.appinfo.description: MariaDB for NGINX Proxy Manager"
    
    - "com.dockstarter.appinfo.nicename: DB NGINX Proxy Manager"
    
    logging:
    
    driver: json-file
    
    options:
    
    max-file: ${DOCKERLOGGING_MAXFILE}
    
    max-size: ${DOCKERLOGGING_MAXSIZE}
    
    ports:
    
    - "3306:3306"
    
    environment:
    
    - "MYSQL_ROOT_PASSWORD:ChangeMe"
    
    - "MYSQL_DATABASE:proxymgr"
    
    - "MYSQL_USER:ChangeMe"
    
    - "MYSQL_PASSWORD:ChangeMe"
    
    - "FORCE_COLOR:1"
    
    volumes:
    
    - /opt/appdata/mariadb:/var/lib/mysql
    
    - ${DOCKERSHAREDDIR}:/shared
    restart: unless-stopped

<!--stackedit_data:
eyJoaXN0b3J5IjpbLTEzODQyNzA3MzksLTcwNTI5NjA2MCwxMT
cwODE2MTc4LC0yMjAzODI0MDNdfQ==
-->