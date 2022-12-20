#!/usr/bin/sudo /bin/bash
set -x ;

wlan=wlp8s0 
mon=mon
chn=4
bw=HT20

if [ $# -ge 3 ]; then
	wlan=$1 ;
	chn=$2 ;
	bw=$3 ;
else
	echo "Usage: $0 wlan chn bw" ;
	echo "- wlan gen mon (monitor type)" ;
	exit ;
fi


#service network-manager stop
nmcli dev set $wlan managed no
#nmcli r wifi off
rfkill unblock wifi ;
#airmon-ng check kill
iw $wlan set power_save off

ifconfig $wlan down
ifconfig $mon > /dev/null 2>&1
if [ $? -ne 0 ]; then
iw dev $wlan interface add $mon type monitor
fi
ifconfig $mon up
#ifconfig $wlan up

#add wlan-managed, will corrupt with wlp8s0, then no-wifi, no-getcsi
#iw dev $wlan interface add wlan type managed
#ifconfig wlan up

#need wlan down, wlp8s0(wlan-managed, mon-monitor)
iw $mon set channel $chn $bw

#service network-manager start


#conclude
#n-virtual-dev in wlp8s0(include wlp8s0), can only up only one,
#so, ./axcsi in monitor need (wlp8s0-down, one-mon-up)


### recover --------------------------------------
#sudo service network-manager restart

