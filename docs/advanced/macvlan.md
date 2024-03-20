# Macvlan Networking

It may help to read the [official documentation](https://docs.docker.com/v17.09/engine/userguide/networking/get-started-macvlan/#macvlan-8021q-trunk-bridge-mode-example-usage) on Macvlan networks, as well as [this tutorial](https://blog.oddbit.com/post/2018-03-12-using-docker-macvlan-networks/) which this page is based on.

## Motivation

There are a few different types of Docker networks. DockSTARTer by default uses a 'bridge' network, which is a virtual network that provides isolation from other networks, but allows containers to communicate with each other.

However, some applications require access to the physical network. Both Home Assistant and Plex need physical network access for discovery (the former will have issues communicating with IoT devices otherwise).

One solution might be to use Docker's `host` network. This however, increases the odds of port conflicts as more containers are added. Docker introduced a Macvlan network for this case which assigns a unique IP and MAC address for attached containers.

## Setup

### On Your Router

- Take note of the IP address of your Docker host and create a DHCP reservation for the IP if there isn't one already.

- Configure DHCP so it will not assign address in a given range. That range will be occupied by our container's addresses.

The rest of this tutorial assumes addresses above `X.X.X.190` will be free.

### On Your Docker Host

- Create the macvlan network (see Note 1):

  ```bash
  docker network create -d macvlan -o parent=<myinterface> --subnet X.X.X.0/24 --gateway X.X.X.1
  --ip-range X.X.X.192/27 --aux-address 'host=X.X.X.Y' mymacvlan
  ```

- `<myinterface>` is the network interface your device is receiving data from. Run `ifconfig` for a listing of possible -nterfaces. Ex: `eth0`
- `subnet` and `gateway` are specific to your LAN subnet
- `ip-range` is the range in which Docker will assign IP addresses. This example goes from `X.X.X.192` to `X.X.X.223`
- `X.X.X.Y` following `host` should be the IP address of your Docker host.

- Add the following to `/etc/network/interfaces` after replacing information as needed:

  ```bash
  # Create new macvlan interface on the host
  ip link add mymacvlanshim link myinterface type macvlan mode bridge
  # Add the host address and bring up the interface
  ip addr add X.X.X.Y/32 dev mymacvlanshim
  ip link set mymacvlanshim up
  # Tell our host to use that interface to communicate with containers
  ip route add 192.168.86.192/27 dev mymacvlanshim
  ```

- Reboot

**Note 1** You may be wondering why we don't create the network in Docker compose. Newer versions of compose have issues with using `aux-address` and `ip-range`.

### In Your DockSTARTer Overrides

We could connect our containers to `mymacvlan` and call it a day, but it's very useful to reserve IPs for each container so we can reach web endpoints in a consistent way.

- Add something similar to this to your `docker-compose.override.yml` file for each container:

  ```yaml
  services:
    watchtower:
      networks:
        composemacvlan:
          ipv4_address: X.X.X.201
  networks:
    composemacvlan:
      external:
        name: mymacvlan
  ```

  The `ipv4` address should fall in the range you reserved.
  Unfortunately, it's necessary to do this when adding new containers if you want them on the same network.

After this, you should be able to compose (`ds -c`) and have a new shiny macvlan network! The containers will be available at the addresses you specified.
