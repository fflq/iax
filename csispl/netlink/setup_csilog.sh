#!/usr/bin/sudo /bin/bash
#ln -sf /lib/firmware/iwlwifi-5000-2.ucode.sigcomm2010 /lib/firmware/iwlwifi-5000-2.ucode
#ls -l /lib/firmware/iwlwifi-5000-* 

modprobe -r iwlwifi mac80211 cfg80211
modprobe iwlwifi connector_log=0x1
exit ;
# Setup monitor mode, loop until it works
iwconfig wlan0 mode monitor 2>/dev/null 1>/dev/null
while [ $? -ne 0 ]
do
	iwconfig wlan0 mode monitor 2>/dev/null 1>/dev/null
done
iw wlan0 set channel $1 $2
ifconfig wlan0 up


#iw dev wlp4s0 connect flqpe
#iw dev wlp4s0 link
#dhclient wlp4s0
#ping ip -i 0.1

