#!/usr/bin/sudo /bin/bash
set -x ;

wlan=wlp4s0 ;

modprobe -r iwlwifi mac80211 cfg80211
#modprobe iwlwifi connector_log=0x1 
modprobe iwlwifi connector_log=1 debug=0x40000

service network-manager stop

ifconfig wlp4s0 down
# Setup monitor mode, loop until it works
iwconfig $wlan mode monitor 2>/dev/null 1>/dev/null
while [ $? -ne 0 ]
do
	iwconfig $wlan mode monitor 2>/dev/null 1>/dev/null
done
#ifconfig $wlan up
#iw $wlan set channel $1 $2
#flq
mon=monm
iw dev $wlan interface add $mon type monitor
ifconfig $wlan up
iw $mon set channel $1 $2
ifconfig $mon up


#service network-manager start

