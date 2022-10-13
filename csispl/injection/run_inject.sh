#!/usr/bin/sudo /bin/bash

wlan=inj0
npac=20
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

echo 0x4101 | sudo tee /sys/kernel/debug/iwlwifi/0000:03:00.0/iwldvm/debug/monitor_tx_rate
echo 0x4101 | sudo tee /sys/kernel/debug/iwlwifi/0000:07:00.0/iwldvm/debug/monitor_tx_rate

#./random_packets 100 100 1 200000
./random_packets $npac 20 1 $nintv $wlan

