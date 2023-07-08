#!/usr/bin/sudo /bin/bash
set -x ;

modprobe -r iwlwifi mac80211 cfg80211
modprobe iwlwifi connector_log=0x1 debug=0x40000
