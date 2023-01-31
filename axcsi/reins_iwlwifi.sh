#!/bin/bash

modprobe -r ath9k 
modprobe -r iwlwifi 
modprobe -r cfg80211 ;
modprobe iwlwifi amsdu_size=3 ;

