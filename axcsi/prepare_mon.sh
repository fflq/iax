#!/bin/bash
set -x

wlan=wlp8s0
if [ $# -ge 1 ]; then
	mod=$1

	sudo modprobe -r $mod
	sudo modprobe $mod 
	sleep 2 
fi

sudo nmcli dev set $wlan managed no
sudo iw dev $wlan set power_save off
sudo ifconfig $wlan down



