# Process Flow Control Wrapper

pfcontrol is a simple wrapper to allow you to start, stop and monitor any service on any server in a uniform way.

pfcontrol evaluates every script to determine if it should be run on an individual server. It then executes whatever logic the script contains and collates the results of all scripts together for consumtion by Nagios or your monitoring tool of choice.

pfcontrol allows quick and easy development of monitoring. Encourages start/stop scripts, log rotation and monitoring to be addressed at system design/build time and provides an low barrier to entry for those unfamiliar with your deployed architecture as each server determines what should be running and thus guides the user to these processes quickly and easily

## setup

pfcontrol expects to run as a non privilged user "monitor". 

```bash
useradd -d /home/monitor monitor
su - monitor
mkdir -p {.cache,logs}
/usr/lib/pfcontrol/bin/pfcontrol selftest
```

##usage

```bash
$ /usr/lib/pfcontrol/bin/pfcontrol status
DEFAULT_COMPONENT: running (pid 3548) 

$ /usr/lib/pfcontrol/bin/pfcontrol alerts
component_bootstrap=0
monitoring_bootstrap=0
server_config_non_standard=0:0
```

