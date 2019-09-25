# AirDC++

[AirDC++](https://www.airdcpp.net/) is an easy to use client for [Advanced Direct Connect](http://en.wikipedia.org/wiki/Advanced_Direct_Connect) and [Direct Connect](http://en.wikipedia.org/wiki/Direct_Connect_(file_sharing)) networks. You are able to join "hubs" with other users, and chat, perform searches and browse the share of each user. 

The GIT Repository for AirDC++ is located at [https://github.com/gangefors/docker-airdcpp-webclient](https://github.com/gangefors/docker-airdcpp-webclient)

## AirDC++ Install

If you see the following error:

> No valid configuration found. Run the application with --configure parameter to set up initial configuration.
>
>

Run the following commands to correct:

```docker stop airdcpp```

```docker run --rm -it --volumes-from airdcpp gangefors/airdcpp-webclient --add-user```

You will be prompted to create a user and password, then run:

```docker start airdcpp```
