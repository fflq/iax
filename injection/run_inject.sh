#!/usr/bin/sudo /bin/bash

wlan=mon0
npac=1000
nintv=500000
if [ $# -ge 1 ]; then
	wlan=$1 ;
fi
if [ $# -ge 2 ]; then
	npac=$2 ;
fi
if [ $# -ge 3 ]; then
	nintv=$3 ;
fi

#./random_packets 100 100 1 200000
./random_packets $npac 20 1 $nintv $wlan

