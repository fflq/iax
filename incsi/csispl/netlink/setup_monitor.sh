#!/usr/bin/sudo /bin/bash
set -x ;


wlan=wlp7s0
chn=64
chn=2
bw=HT20
if [ $# -ge 1 ]; then
	wlan=$1
fi
if [ $# -ge 2 ]; then
	chn=$2
fi
if [ $# -ge 3 ]; then
	bw=$3
fi 

#unload will make monitor to managed, so comment tempoarily
#modprobe -r iwlwifi mac80211 cfg80211
#modprobe iwlwifi connector_log=0x1 debug=0x40000
#0b100,for rx_mpdu; 0b1,for bfee_notif
modprobe iwlwifi connector_log=0x1 debug=0x40000

#service network-manager stop
#killall wpa_supplicant


source ./set_monitor_func.sh ;

set_monitor_func $wlan $chn $bw 

#service network-manager start






