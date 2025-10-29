#!/usr/bin/sudo /bin/bash
#set -x ;

echo "* update fws"
#cd $(dirname ${BASH_SOURCE[0]})
iax_iwlwifi_dir=$(dirname ${BASH_SOURCE[0]})

dt=$(date +'%Y%m%d') ;

# firmware
os_firmware_dir="/lib/firmware/" ;
iax_firmware_dir="${iax_iwlwifi_dir}/iaxcsi-linux-firmware/" ;
iwlwifi_backup_dir="${os_firmware_dir}/bak-iwlwifi" ;
iwlwifi_backup_dt_dir="${iwlwifi_backup_dir}-${dt}" ;

if [ ! -d $iax_firmware_dir ]; then
	echo "* not found iax fws";
	exit;
fi

mkdir -p $iwlwifi_backup_dt_dir
echo "* move os fws"
mv -vf $os_firmware_dir/iwlwifi-{5000,so,ty}* $iwlwifi_backup_dt_dir ;

mkdir -p $iwlwifi_backup_dir
if [ -z "$(ls -A ${iwlwifi_backup_dir})" ]; then
	echo "* backup original related fws"
	cp -rvf $iwlwifi_backup_dt_dir/* $iwlwifi_backup_dir
fi

echo "* move iax fws"
cp -rvf $iax_firmware_dir/iwlwifi-* $os_firmware_dir ;


## handle 5300 fws
echo "* ln i53"
ln -vsf ${os_firmware_dir}/iwlwifi-5000-2.ucode.sigcomm2010 ${os_firmware_dir}/iwlwifi-5000-2.ucode ;
ln -vsf ${os_firmware_dir}/iwlwifi-5000-2.ucode.sigcomm2010 ${os_firmware_dir}/iwlwifi-5000-5.ucode ;

echo "done"
ls ${os_firmware_dir}/iwlwifi-{so,ty,5000}*

