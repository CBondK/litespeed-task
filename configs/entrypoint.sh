#!/bin/bash

[ -f /usr/local/lsws/conf/trial.key ] && rm -f /usr/local/lsws/conf/trial.key

/usr/local/lsws/bin/lshttpd -t

/usr/local/lsws/bin/lswsctrl start

$@

while true; do
  if ! /usr/local/lsws/bin/lswsctrl status | grep 'litespeed is running with PID *' > /dev/null; then
    break
  fi
    sleep 60
done
