#!/usr/bin/sudo /bin/bash
set -x ;


make -j4 ;
make modules_install ;

#./cleanupdates.sh
depmod ;

modprobe -r iwlwifi 
modprobe -r ath9k ;
modprobe -r cfg80211 ;
modprobe -r rt2800usb ;
#modprobe iwlwifi amsdu_size=3 bt_coex_active=0
modprobe iwlwifi 

pkill wpa_supplicant ;
systemctl restart NetworkManager.service

sleep 1 ;
echo 1 | sudo tee /sys/kernel/debug/iwlwifi/0000:08:00.0/iwlmvm/csi_enabled ;
#cat mem ;
#echo 1 > /sys/kernel/debug/iwlwifi/0000:08:00.0/iwlmvm/csi_enabled ;
#sudo cat /sys/kernel/debug/iwlwifi/0000:08:00.0/iwlmvm/mem ;


sudo ./reins_iwlwifi.sh 


