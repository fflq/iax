#!/usr/bin/sudo /bin/bash
#set -x ;


wlan=wlp8s0 
mon=mon0
chn=40
chtype=HT20
if [ $# -ge 3 ]; then
	wlan=$1 ;
	chn=$2 ;
	chtype=$3 ;
else
	echo "Usage: $0 wlan chn chtype" ;
	echo " - wlan: gen mon (is monitor type)" ;
	echo " - chn: channel"
	echo " - chtype: custom format. eg HT40 VHT80 HE160"
	echo " * eg: $0 wlp3s0 64 HT20"
	echo " * eg: $0 wlp3s0 64 VHT40-"
	echo " * eg: $0 wlp3s0 40 HE160"
	exit -1 ;
fi



echo "* $0 $wlan $chn $chtype"

echo "" 
sudo ./setup_monitor.sh $wlan $chn $chtype
if [ $? -ne 0 ]; then
	exit -1 ;
fi

echo "" 
sudo ./activate.sh 10000 $chtype 00:16:ea:12:34:56
if [ $? -ne 0 ]; then
	exit -1 ;
fi


echo ""
echo "* setup succ"
exit 0 ;



