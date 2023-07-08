#!/usr/bin/sudo /bin/bash
set -x ;

tools_dir=$(dirname ${BASH_SOURCE[0]})

if [ $# -ge 1 ]; then
	${tools_dir}/cleanupdates.sh
	shift
fi

make -j4 ;
make modules_install ;
depmod ;

${tools_dir}/reins_csi_iwlwifi.sh

#pkill wpa_supplicant ;
#systemctl restart NetworkManager.service

#custom flqu
sleep 1 ;
echo 1 | sudo tee /sys/kernel/debug/iwlwifi/0000:08:00.0/iwlmvm/csi_enabled ;


