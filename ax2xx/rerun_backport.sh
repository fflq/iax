#!/usr/bin/sudo /bin/bash
set -x ;


make -j4 ;
make modules_install ;

#./cleanupdates.sh
depmod ;

modprobe -r iwlwifi 
modprobe -r ath9k ;
modprobe -r cfg80211 ;
modprobe iwlwifi ;

sleep 1 ;
echo 1 > /sys/kernel/debug/iwlwifi/0000:08:00.0/iwlmvm/csi_enabled ;

pkill wpa_supplicant ;

sleep 1 ;
cat /sys/kernel/debug/iwlwifi/0000:08:00.0/iwlmvm/mem ;


