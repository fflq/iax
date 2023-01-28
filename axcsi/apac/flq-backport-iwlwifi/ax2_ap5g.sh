#!/bin/bash

wlan=wlp8s0 
wifiname=seeyou
wifipwd=
if [ $# -ge 3 ]; then
	wlan=$1 ;
	wifiname=$2 ;
	wifipwd=$3 ;
fi

#must 5g-wifi, help init for 5g-ap
wlan_wifi5g=$wlan
wlan_ap5g=$wlan


#sudo service network-manager stop ;
#sudo rfkill unblock wlan ;
#sudo airmon-ng check kill ;

#sudo ifconfig $wlan_wifi5g up ;
#sudo ifconfig $wlan_ap5g up ;

sudo ifconfig $wlan_wifi5g down 
ifconfig sta > /dev/null 2>&1 
if [ $? -ne 0 ]; then
sudo iw dev $wlan_wifi5g interface add sta type managed
fi
sudo ifconfig sta up
sudo ./connwifi.sh sta $wifiname $wifipwd


#max 40MHz, can 80MHz
#sudo create_ap --ieee80211n --ieee80211ac --ht_capab "[HT20][HT40-][SHORT-GI-20][SHORT-GI-40]" --vht_capab "[VHT80][RXLDPC][SHORT-GI-80][TX-STBC-2BY1][RX-STBC-1]" -c 157 wlp8s0 sta test 88888888
#HT_CAPAB=[HT40+][SHORT-GI-20][SHORT-GI-40]
#VHT_CAPAB=[VHT80][RXLDPC][SHORT-GI-80][TX-STBC-2BY1][RX-STBC-1]
sudo create_ap --config ./create_ap5.conf

#can 80MHz
#sudo iw dev $wlan_wifi5g interface add apn type __ap
#sudo ifconfig apn up
#sudo ./hostapd-2.10/hostapd/hostapd ./flquap_hostapd6.conf


#sudo ifconfig sta down


