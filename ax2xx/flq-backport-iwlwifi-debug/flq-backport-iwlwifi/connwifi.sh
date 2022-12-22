#!/usr/bin/sudo /bin/bash

wlan=wlp8s0 
if [ $# -gt 1 ]; then
	wlan=$1 ;
fi

pkill wpa_supplicant 
#use system auto
exit 0
wpa_supplicant -Dnl80211 -i$wlan -c./wpa.conf -B
dhclient $wlan

