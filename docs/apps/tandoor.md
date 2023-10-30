# Sonarr

[![Docker Pulls](https://img.shields.io/docker/pulls/vabene1111/recipes?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/vabene1111/recipes)
[![GitHub Stars](https://img.shields.io/github/stars//vabene1111/recipes?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com//vabene1111/recipes)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/tandoor)

## Description

[Tandoor](https://docs.tandoor.dev/) is a recipe manager and so much more.
You can import recipes from thousands of websites, generate mealplans, manage your shopping list.
Share and collaborate with your friends and family using a mobile friendly web interface.

## Install/Setup

This application has extensive customization options, most docker env variables are documented in the [.env.template](https://raw.githubusercontent.com/vabene1111/recipes/master/.env.template)
If you run into any issues, enable debug mode to collect logs before opening a ticket.
```
  tandoor:
    environment:
    - DEBUG=1
```

### Running with PostgreSQL
It is highly recommended to use this application with a PostgreSQL database.
To setup with postgres, after installing a postgres server (or enabling the DockSTARTer app) create a database and edit docker-compose.override.yml similar to below.
```
  tandoor:
    environment:
    - DB_ENGINE=django.db.backends.postgresql
    - POSTGRES_HOST=postgres
    - POSTGRES_PORT=5432
    - POSTGRES_USER=tandoor_user
    - POSTGRES_PASSWORD=tandoor_user_password
    - POSTGRES_DB=tandoor_db
    depends_on: //optional: if using a postgres container
      - db_recipes
```

### Running with SWAG
It is also highly recommended to serve media files with a web server.  If you are already using SWAG you can use nginx to accomplish this.
Edit the docker-compose.override.yml similar to below.
