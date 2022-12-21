#!/usr/bin/sudo /bin/bash
#set -x ;


wlan=wlp8s0 
mon=mon
chn=4
chtype=HT20
if [ $# -ge 3 ]; then
	wlan=$1 ;
	chn=$2 ;
	chtype=$3 ;
else
	echo "Usage: $0 wlan chn chtype" ;
	echo " - wlan: gen 'mon' (is monitor type)" ;
	echo " - chn: channel"
	echo " - chtype: custom format. eg HT40 VHT80 HE160"
	echo " * eg: $0 wlp3s0 64 HT20"
	echo " * eg: $0 wlp3s0 64 VHT40-"
	echo " * eg: $0 wlp3s0 40 HE160"
	exit -1 ;
fi
echo "* $0 $wlan $chn $chtype"



#flq_chtype => iw_chtype
declare -A iw_chtype_map
iw_chtype_map=([NOHT]=NOHT [HT20]=HT20 [HT40]=HT40 [HT40-]=HT40- [HT40+]=HT40+\
	[VHT20]=HT20 [VHT40]=HT40 [VHT40-]=HT40- [VHT40+]=HT40+ [VHT80]=80MHz [VHT160]=160MHz \
	[HE20]=HT20 [HE40]=HT40 [HE40-]=HT40- [HE40+]=HT40+ [HE80]=80MHz [HE160]=160MHz)
iw_chtype_keys=${!iw_chtype_map[*]}
iw_chtype_vals=${iw_chtype_map[*]}
if [ "${iw_chtype_map[$chtype]}" = "" ]; then
	echo "* err. invalid chtype: ($chtype)" ;
	echo "* valid chtype: ($iw_chtype_keys)" ;
	exit -1 ;
fi
iw_chtype=${iw_chtype_map[$chtype]}



#service network-manager stop
nmcli dev set $wlan managed no > /dev/null 2>&1
#nmcli r wifi off
rfkill unblock wifi ;
#if not work, check kill
ret=$(iw dev | grep -A1 monitor | grep $chn)
if [ "$ret" == "" ]; then
	airmon-ng check kill
fi
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
iw $mon set channel $chn $iw_chtype
if [ $? -ne 0 ]; then
	echo "* err(iw $mon set channel $chn $iw_chtype)"
	if [ "$iw_chtype" = "160MHz" ]; then
		echo "* please update iw to support 160MHz setting"
		echo "* (git clone https://git.sipsolutions.net/iw.git)"
	fi
	exit -1 ;
fi

#service network-manager start


#conclude
#n-virtual-dev in wlp8s0(include wlp8s0), can only up only one,
#so, ./axcsi in monitor need (wlp8s0-down, one-mon-up)


### recover --------------------------------------
#sudo service network-manager restart


exit 0 ;
