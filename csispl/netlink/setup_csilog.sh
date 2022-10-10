#!/usr/bin/sudo /bin/bash
set -x ;


wlan=wlp1s0
chn=64
bw=HT20
if [ $# -ge 2 ]; then
	wlan=$1
	chn=$2
	bw=$3
fi 

modprobe -r iwlwifi mac80211 cfg80211
#modprobe iwlwifi connector_log=0x1 debug=0x40000
#0b100,for rx_mpdu; 0b1,for bfee_notif
modprobe iwlwifi connector_log=0x1 debug=0x40000

#service network-manager stop
#killall wpa_supplicant


source ./set_monitor_func.sh ;

set_monitor_func $wlan $chn $bw 

#service network-manager start






