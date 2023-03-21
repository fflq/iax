#!/bin/bash

modprobe -r ath9k 
modprobe -r iwlwifi 
modprobe -r cfg80211 ;
modprobe iwlwifi fw_restart=0 bt_coex_active=0 ;

