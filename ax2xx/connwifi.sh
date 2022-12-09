#!/bin/bash
##!/usr/bin/sudo /bin/bash

wlan=wlp8s0 
wifiname=seeyou
wifipwd=
if [ $# -ge 3 ]; then
	wlan=$1 ;
	wifiname=$2 ;
	wifipwd=$3 ;
fi

sudo service network-manager stop
sudo rfkill unblock all ;

#conn wifi by sta
echo "* run sta conn $wifiname" ;
sudo pkill wpa_supplicant
#wifi_conf=/tmp/wifi.$(date +%s).conf
wifi_conf=/tmp/wifi.$(date +"%Y%m%d").conf
sudo wpa_passphrase $wifiname $wifipwd > $wifi_conf ;
sudo wpa_supplicant -B -i $wlan -c $wifi_conf -s -O /run/flq_wpa ;

echo "* run dhclient"
sudo pkill dhclient
sudo dhclient $wlan

