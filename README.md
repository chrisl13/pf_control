# Process Flow Control Wrapper

pfcontrol is a simple wrapper to allow you to start, stop and monitor any service on any server in a uniform way.

pfcontrol evaluates every script to determine if it should be run on an individual server. It then executes whatever logic the script contains and collates the results of all scripts together for consumtion by Nagios or your monitoring tool of choice.

pfcontrol allows quick and easy development of monitoring. Encourages start/stop scripts, log rotation and monitoring to be addressed at system design/build time and provides an low barrier to entry for those unfamiliar with your deployed architecture as each server determines what should be running and thus guides the user to these processes quickly and easily
