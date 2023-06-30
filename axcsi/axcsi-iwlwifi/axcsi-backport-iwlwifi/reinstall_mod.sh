#!/bin/bash

modprobe -r $1 
modprobe -r cfg80211 ;
modprobe $1 ;
