#!/usr/bin/sudo /bin/bash

 sudo iw wlp8s0 interface add mon0 type monitor
 sudo airodump-ng mon0

