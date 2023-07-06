#!/bin/bash

modprobe -r ath9k 
modprobe -r iwlwifi mac80211 cfg80211

#modprobe iwlwifi connector_log=0x1 debug=0x40000
#modprobe iwlwifi amsdu_size=3 ;
modprobe iwlwifi connector_log=0x1 debug=0x40000 amsdu_size=3 ;

