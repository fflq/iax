#!/usr/bin/sudo /bin/bash
set -x
wlan=wlp8s0

modprobe -r iwlwifi mac80211 cfg80211
#modprobe iwlwifi debug=0x40000
modprobe iwlwifi connector_log=1 debug=0x40000

service network-manager stop
ifconfig $wlan down
ifconfig $wlan 2>/dev/null 1>/dev/null
while [ $? -ne 0 ]
do
	        ifconfig $wlan 2>/dev/null 1>/dev/null
done
iw dev $wlan interface add mon0 type monitor
ifconfig $wlan up
iw mon0 set channel $1 $2
ifconfig mon0 up


#service network-manager start

