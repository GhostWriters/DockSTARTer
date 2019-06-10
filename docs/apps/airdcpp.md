If you see the following error:

> No valid configuration found. Run the application with --configure parameter to set up initial configuration.
>
>

Run the following commands to correct:

```docker stop airdcpp```

```docker run --rm -it --volumes-from airdcpp gangefors/airdcpp-webclient --add-user```

You will be prompted to create a user and password, then run:

```docker start airdcpp```
