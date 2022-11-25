#!/usr/bin/sudo /bin/bash
set -x ;

sudo apt install libssl-dev ;

git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git ;
if [ $? -eq 0 ]; then
#mv /lib/firmware/iwlwifi-* /lib/firmware/backup-iwlwifi/ ;
#cp linux-firmware/iwlwifi-* /lib/firmware/ ;
fi

git clone https://git.kernel.org/pub/scm/linux/kernel/git/iwlwifi/backport-iwlwifi.git ;
if [ $? -eq 0 ]; then
	cd backport-iwlwifi ;
	make_backport_iwlwifi $wlan ;
fi


make_backport_iwlwifi() {
	pci=$(lspci -D | grep '2725\|210' | awk '{print $1}') ; 
	if [ "$pci" == "" ]; then
		echo "* no find ax210 pciid, exit." ;
		exit -1 ;
	fi
	echo "* for pci($pci)" ;


	make -j4 ;
	make modules_install ;

	#./cleanupdates.sh
	depmod ;

	modprobe -r iwlwifi 
	modprobe -r ath9k ;
	modprobe -r cfg80211 ;
	modprobe iwlwifi amsdu_size=3 ; 

	pkill wpa_supplicant ;
	systemctl restart NetworkManager.service

	sleep 1 ;
	#echo 1 > /sys/kernel/debug/iwlwifi/$pci/iwlmvm/csi_enabled ;
	cd /sys/kernel/debug/iwlwifi/$pci/iwlmvm/ ;
	echo 1 > csi_enabled ; 
}



