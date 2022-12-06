#!/usr/bin/sudo /bin/bash
#set -x ;

intval_us=100000
if [ $# -ge 1 ]; then
	intval_us=$1 ;
fi

pci=$(lspci -D | grep '2725\|210' | awk '{print $1}') ; 
if [ "$pci" == "" ]; then
	echo "* no find ax210 pciid, exit." ;
	exit -1 ;
fi
echo "* for pci($pci)" ;

cd /sys/kernel/debug/iwlwifi/$pci/iwlmvm/ ;
echo $intval_us > csi_interval ;
echo 1 > csi_enabled ; 

