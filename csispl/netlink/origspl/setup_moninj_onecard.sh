#!/usr/bin/sudo /bin/bash
set -x ;

wlan=wlp4s0 
# mon/inj diff
#mode=mode monitor
mode=

modprobe -r iwlwifi mac80211 cfg80211
modprobe iwlwifi connector_log=0x1 debug=0x40000

service network-manager stop

ifconfig $wlan down
# Setup monitor mode, loop until it works
iwconfig $wlan $mode 2>/dev/null 1>/dev/null
while [ $? -ne 0 ]
do
	iwconfig $wlan $mode 2>/dev/null 1>/dev/null
done

mon=monm
iw dev $wlan interface add $mon type monitor
iw dev $wlan interface add mon0 type monitor
ifconfig $wlan up
iw $mon set channel $1 $2
iw mon0 set channel $1 $2
ifconfig $mon up
ifconfig mon0 up


#service network-manager start


