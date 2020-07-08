# Calibre-web

[Calibre-web](https://github.com/janeczku/calibre-web) is a web app providing a clean interface for browsing, reading and downloading eBooks using an existing [Calibre](https://calibre-ebook.com/) database. It is also possible to integrate google drive and edit metadata and your calibre library through the app itself.

The GIT Repository for Calibre-web is located at [https://github.com/linuxserver/docker-calibre-web](https://github.com/linuxserver/docker-calibre-web)

## Calibre-web installation

The Calibre-web docker is only a web front end to the actual Calibre application/database itself. You still need a Calibre  metadata.db file for Calibre Web to function. To get this, you have to install [Calibre](https://calibre-ebook.com/download) somewhere and you can move the metadata.db file into either your /books or /shared folder.
