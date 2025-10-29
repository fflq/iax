#!/usr/bin/sudo /bin/bash
#set -x ;

os_firmware_dir="/lib/firmware/";
iwlwifi_backup_dir="${os_firmware_dir}/bak-iwlwifi";

echo "* restore iwlwifi fws"
if [ -d ${iwlwifi_backup_dir} ]; then
	if [ -L ${os_firmware_dir}/iwlwifi-5000-5.ucode ]; then
		rm -vf ${os_firmware_dir}/iwlwifi-5000-*.ucode;
	fi

	cp -rvf $iwlwifi_backup_dir/* $os_firmware_dir;
fi

echo "done"
ls ${os_firmware_dir}/iwlwifi-{so,ty,5000}*
