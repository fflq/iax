#!/usr/bin/sudo /bin/bash
set -x ;


sudo apt update ;

sudo apt install flex bison -y ;
sudo apt install libnl-3-dev libnl-genl-3-dev -y ;
sudo apt install iw net-tools -y ;
sudo apt install build-essential -y ;
sudo apt install pkgconf libpcap-dev libssl-dev -y ;
sudo apt install aircrack-ng -y ;
#exit 0 ;


dt=$(date +"%Y%m%d") ;
backup_iwlwifi_dir="/lib/firmware/backup-iwlwifi-$dt" ;
sudo mkdir $backup_iwlwifi_dir ;
sudo mv /lib/firmware/iwlwifi-* $backup_iwlwifi_dir/ ;
sudo cp ./flq-linux-firmware/iwlwifi-* /lib/firmware/ ;


cd .flq-backport-iwlwifi ;
sudo ./rerun_backport.sh ;


cd ../injection ;
sudo ./run.sh ;


cd ../csi ;
make ;

