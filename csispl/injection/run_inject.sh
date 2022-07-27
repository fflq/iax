#!/bin/bash

npac=20
nintv=500000
if [ $# -ge 1 ]; then
	npac=$1 ;
fi
if [ $# -ge 2 ]; then
	nintv=$2 ;
fi

echo 0x4101 | sudo tee /sys/kernel/debug/iwlwifi/0000:03:00.0/iwldvm/debug/monitor_tx_rate

#./random_packets 100 100 1 200000
./random_packets $npac 20 1 $nintv

