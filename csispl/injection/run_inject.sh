#!/bin/bash


echo 0x4101 | sudo tee /sys/kernel/debug/iwlwifi/0000:08:00.0/iwldvm/debug/monitor_tx_rate

#./random_packets 100 100 1 200000
./random_packets 5000 20 1 300000

