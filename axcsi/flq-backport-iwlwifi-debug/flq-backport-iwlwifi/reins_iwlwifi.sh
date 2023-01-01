#!/bin/bash

modprobe -r ath9k 
modprobe -r iwlwifi 
modprobe -r cfg80211 ;
modprobe iwlwifi bt_coex_active=0 ;

