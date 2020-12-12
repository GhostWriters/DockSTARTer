# Nextcloud

[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/nextcloud?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/linuxserver/nextcloud)
[![GitHub Stars](https://img.shields.io/github/stars/linuxserver/docker-nextcloud?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/linuxserver/docker-nextcloud)

## Description

[Nextcloud](https://nextcloud.com/) gives you access to all your files wherever you are.

### Configuring Nextcloud

If you are running the DockSTARTer Nextcloud container behind a SWAG reverse proxy, you may need to add a extra line to the NextCloud config.php file so it can find it.

Without configuring this you will be able to access the web page, but apps may timeout or return an invalid password.

Run the below command and add the line to the the config.php file before the `);`

```bash
nano /config/www/nextcloud/config/config.php
```

Copy the following line:
`'overwritehost' => 'hostname',`

Where your `hostname` is the URL you use to access your NextCloud web interface, **make sure you include the comma at the end**.

Doing this will allow the apps to pass the username/password through to the application.

# Settings for Onedrive with Nextcloud

    --------------------
    [OneDrive]
    type = onedrive
    token = {"access_token":"EwBoA8l6BAAUO9chh8cJscQLmU+LSWpbnr0vmwwAAZbhk2/L/5yRyhcD1rW/3nJyL84BpioH0DC7a8vZS1JocPnOrVDKxsJKOxTMN+Ws3eIAWZs2woZR7dRvwiMECxUBQdh2w3Ovpj9aDSYuG/UPuOnN463q7BZ62Y6TrvOc57ROnyfXujVkgQpdd1P4Gb+rs2/EH0qROoIhHQRIbnBqdXTXgY4fVhBwgQffz9jahE3eBYygvQiLZ47gogL3YGtW/0krc+nF0jW0hhyVNf4dMecx51gLTqFXeJJpWTomDzivzDBZaXLQ9o/r709KlAisji67kYN7FLgQYtqgLQPuQlowWb4VcxJTjLLC959x1Vg67wlA4GP1MwvfLUZR1oYDZgAACOeeWnJL/uQYOAIAyLev2EThRIOSbEV3/BubH81EmHpbtALAGU+mDX/Q77inFkgvcB3dhDssJ+QC4kK6ss4l7mbCP13gWOCusPhtDCosDNA+/mAjjRS1PE7y1QzS5n5hsEBk541iaQOfw4R8vHwHxWIO8EOOm9mc3GaIsStm7LjGi4rqbSZclqnyFKNY/ZNW2fOuyHoc5LbE2XalU+U8HIvtZkVJwOTSf157fYrwAMvW8HJhO2VPRp5wyx5hTYrK57Oe8ZE1gDeNBYxK4MVskQPkS3Ax6r8Bf6vOBSFoU8KWuvhSxiO/pWJ+fa6/AIUjZpFJ6ilcRlhZjGdKd3IPcjcuPqVe19f5uP1RxSNJ583qXKOn9AIiSetoWUfU6CtL5fwAuejwhBR4wpZMhjFBkiv+1DXYB9n2/LB4y9vHh1Sc79k3Uq+d/dYH5H+ayZMCXrroEtVbSuU7dZjcuy+Lx42bI/56A63AkTcBieUDwQGn/wOjx7pacOPR4nEBWncGU+CshteEuy86pisTqfKeINevyIhJLXyKko2yCLm1vpegZrSj0fkTXnBzGVpAQlwNmm5JGX7JBB51jTZsfqIEyifNlvYiyOrRYtxQHClBzFdjnOev+oj9vxIz+Pzqmgbhr2mCEchmYFNCg3QQeuZrTKQzBtvTaBmduYykPNUQcC1VbPfUb2I8A74SoxK1vT80a5DUH0HBZgH5enYnMeJE3DD7Uy5Q9E1/h/gZXhx+mgr1j/l0VeiWr9W1IrBANvu5gS+EcAI=","token_type":"Bearer","refresh_token":"M.R3_BL2.CU3fkZSPgyr4h6fU1Apokb8Yzy2HyFkspJ5MAWKTGwqdMCnkD2TyAirjSdONkgCI4My8xn6ckFx5sxVhPngOSfY096pTJsd3ISyYcimXVdh*e3prIzNUNCB8xY10XnRdMYpmD4HDtQy!Ym*qnZLaJdVbTZgXRJDK4kzbH6EVRlRATazZyQX26aoTACckAElV4C!YDdHObpjm1i*XqbByDaEK5EbRGjZvR1MSkN!NSR6xGvRWpYENm0KEo*QSt2l!iigN0fwifDN!krUeksSWq*!uPfhd2tvhgtEz!6FfToXSl!mK9aMGOcESye8ixv4GK1YQ!nDiFP7w5YBd71aMIuBUfcukzERHkNwIq4NkiJil2ESQxV7w3UGwHHFGmh*tHd*HtvFfaAG0kcxe5GZh8ad2yZlgnNPJrYywVf*pBaXlOmiE8qq0wH7w7JITNAdO*w$$","expiry":"2020-10-09T00:00:09.576713+10:30"}
    drive_id = c71d7fe8861429a5
    drive_type = personal
    --------------------