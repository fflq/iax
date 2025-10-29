#!/usr/bin/sudo /bin/bash
#set -x ;

echo "* setup csi iwlwifi"

iax_iwlwifi_dir=$(dirname ${BASH_SOURCE[0]})

if [ -z "$(uname -r | grep '5.15')" ]; then
   echo "* please change kernel $(uname -r) to 5.15.*"
   exit;
fi

# apt
sudo apt update ;
sudo apt install flex bison -y ;
sudo apt install libnl-3-dev libnl-genl-3-dev -y ;
sudo apt install git iw net-tools hostapd -y ;
sudo apt install build-essential -y ;
sudo apt install pkgconf libpcap-dev libssl-dev -y ;
sudo apt install aircrack-ng -y ;

# firmware
sudo $iax_iwlwifi_dir/update-firmware.sh

# iwlwifi
sudo $iax_iwlwifi_dir/remake-csi-iwlwifi.sh ;

echo "done"

