#!/usr/bin/sudo /bin/bash
#set -x ;

pci=$(lspci -D | grep '2725\|210' | awk '{print $1}') ; 
if [ "$pci" == "" ]; then
	echo "* no find ax210 pciid, exit." ;
	exit -1 ;
fi
echo "* for pci($pci)" ;

cd /sys/kernel/debug/iwlwifi/$pci/iwlmvm/ ;
echo 1 > csi_enabled ; 

