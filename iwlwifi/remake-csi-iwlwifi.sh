#!/usr/bin/sudo /bin/bash
#set -x ;

iax_iwlwifi_dir=$(dirname ${BASH_SOURCE[0]})
codes_dir=${iax_iwlwifi_dir}/iaxcsi-iwlwifi

if [ ! -f $codes_dir/Kconfig ]; then
	echo "* not find iwlwifi driver cods dir"
	exit;
fi

if [ $# -ge 1 ]; then
	${iax_iwlwifi_dir}/clean_updates.sh
	shift
fi

echo "* making"
make -j4 -C $codes_dir;
make modules_install -C $codes_dir;
depmod ;

${iax_iwlwifi_dir}/reload-csi-iwlwifi.sh

#pkill wpa_supplicant ;
#systemctl restart NetworkManager.service

#custom flqu
#sleep 1 ;
#echo 1 | sudo tee /sys/kernel/debug/iwlwifi/0000:08:00.0/iwlmvm/csi_enabled ;
