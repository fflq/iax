#!/bin/bash


cd ../injection
./run_inject.sh &

#../netlink/log_to_file /tmp/a.log  
../netlink/log_to_remote

