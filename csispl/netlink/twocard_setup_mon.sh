#!/usr/bin/sudo /bin/bash
set -x ;


chn=64
bw=HT20
if [ $# -ge 2 ]; then
	chn=$1
	bw=$2
fi 

modprobe -r iwlwifi mac80211 cfg80211
#modprobe iwlwifi connector_log=0x1 debug=0x40000
#0b100,for rx_mpdu; 0b1,for bfee_notif
modprobe iwlwifi connector_log=0x1 debug=0x40000

service network-manager stop
killall wpa_supplicant


set_monitor() {
	if [ $# -lt 1 ]; then
		echo "error mon_wal" ;
		return ;
	fi
	echo "set $1 monitor" ;
## recv
	mon_wlan=$1 
	ifconfig $mon_wlan down
# Setup monitor mode, loop until it works
	iwconfig $mon_wlan mode monitor 2>/dev/null 1>/dev/null
	while [ $? -ne 0 ]
	do
		iwconfig $mon_wlan mode monitor 2>/dev/null 1>/dev/null
		sleep 1
	done
	ifconfig $mon_wlan up
	iw $mon_wlan set channel $chn $bw
}


set_monitor wlp4s0 
set_monitor wlp8s0 

#service network-manager start






