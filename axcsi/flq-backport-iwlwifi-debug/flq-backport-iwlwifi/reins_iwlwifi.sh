#!/bin/bash

modprobe -r ath9k 
modprobe -r iwlwifi 
modprobe -r cfg80211 ;
<<<<<<< HEAD
modprobe -r rt2800usb ;
#modprobe iwlwifi fw_restart=0 bt_coex_active=0 ;
modprobe iwlwifi fw_restart=0 ;
=======
modprobe iwlwifi fw_restart=0 bt_coex_active=0 ;
>>>>>>> 2821d0cf5b07413cdf4972d79128ca68625859f9

