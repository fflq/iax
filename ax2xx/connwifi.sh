#!/usr/bin/sudo /bin/bash

wlan=wlp8s0 
if [ $# -gt 1 ]; then
	wlan=$1 ;
fi

#use system auto
pkill wpa_supplicant 
exit 0
wpa_supplicant -Dnl80211 -i$wlan -c../hostapd/wpa.conf -B
dhclient $wlan

