#!/usr/bin/sudo /bin/bash
set -x ;


sudo apt update ;

sudo apt install flex bison -y ;
sudo apt install libnl-3-dev libnl-genl-3-dev -y ;
sudo apt install git iw net-tools hostapd -y ;
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
cd ..


cd injection ;
sudo ./run.sh ;
cd ..


cd csi ;
make ;
cd ..


while [ ! -e iw ]
do
git clone https://git.sipsolutions.net/iw.git
cd iw 
make && make install
cd ..
done


while [ ! -e create_ap ]
do
git clone https://github.com/dlenski/create_ap.git
cd 
make install
cd ..
done




