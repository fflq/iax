#!/usr/bin/sudo /bin/bash
set -x ;

dt=$(date +'%Y%m%d') ;


#apt
sudo apt update ;
sudo apt install flex bison -y ;
sudo apt install libnl-3-dev libnl-genl-3-dev -y ;
sudo apt install git iw net-tools hostapd -y ;
sudo apt install build-essential -y ;
sudo apt install pkgconf libpcap-dev libssl-dev -y ;
sudo apt install aircrack-ng -y ;


#firmware
dst_firmware_dir="/lib/firmware/" ;
dst_iwlwifi_firmwares="${dst_firmware_dir}/iwlwifi-*" ;
iwlwifi_backup_dir="${dst_firmware_dir}/iwlwifi-${dt}/" ;
mkdir $iwlwifi_backup_dir ;
cp -rf $dst_iwlwifi_firmwares $iwlwifi_backup_dir ;
mv -rf $dst_iwlwifi_firmwares /tmp/ ;
##new firmwares
src_iwlwifi_firmwares="./flq-linux-firmware/*" ;
cp -rf $src_iwlwifi_firmwares $dst_firmware_dir ;
##handle 5300 fws
ln -s ${dst_firmware_dir}/iwlwifi-5000-2.ucode.sigcomm2010 ${dst_firmware_dir}/iwlwifi-5000-2.ucode ;
ln -s ${dst_firmware_dir}/iwlwifi-5000-2.ucode.sigcomm2010 ${dst_firmware_dir}/iwlwifi-5000-5.ucode ;



