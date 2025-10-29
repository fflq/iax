#!/usr/bin/sudo /bin/bash

echo "* reload iwlwifi"
#modprobe -r ath9k 
sudo modprobe -r iwlwifi mac80211 cfg80211

#modprobe iwlwifi connector_log=0x1 debug=0x40000
#modprobe iwlwifi amsdu_size=3 ;
sudo modprobe iwlwifi connector_log=0x1 debug=0x40000 amsdu_size=3 ;

# disable iwlwifi debug log
echo 1 | sudo tee /sys/module/iwlwifi/parameters/debug 2>/dev/null;

echo "done"

