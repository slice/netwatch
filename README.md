# `netwatch`

netwatch watches your network using `nmcli` (`networkmanager`) and restarts it
if something goes wrong.

## how it works

nw opens a ping process, and monitors the time it takes to ping your ping
address (default: `8.8.8.8`). it also detects if the network is unreachable.

if the network becomes to slow or the network becomes unreachable, it is
revived.

### network revival

1. network is restarted
2. wait until connectivity to the network
3. wait for internet connection (using ping)
4. restrt ping, monitor your network

## compiling

### prerequisites

- lua 5.3 (untested with other versions)
- luarocks
- moonscript
- luasocket (sleep)

use moonscript to compile `nw.moon`

## notification support

`notify-send` will be used to send you notifications when your network is being
revived or it has been revived. you will only see these notifications if your
notification daemon is running.
