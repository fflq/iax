#!/usr/bin/sudo /bin/bash
#set -x ;



#[function usage]
if [ $# -ge 1 ] && [ "$1" = "-h" ]; then
echo "Usage: $0 [chtype] [interval_us] [macs]" 
echo " - chtype: chtype for inject rate. eg. HT20 VHT40 HE160"
echo " - interval_us: recv csi interval"
echo " - macs: filtered macs"
echo " * eg: $0 VHT40- 100000 00:16:ea:12:34:56"
echo ""
exit ;
fi


#[function handle args]
chtype=NOHT
interval_us=10000
#macs=00:16:ea:12:34:56

if [ $# -gt 0 ]; then
	chtype=$1 ;
	shift
fi
if [ $# -gt 0 ]; then
	interval_us=$1 ;
	shift
fi
if [ $# -gt 0 ]; then
	macs=$* ;
fi
chtype=${chtype^^};



#[function get_pci]
pci_ids=$(lspci -D | grep 'AX200\|AX201\|2725\|AX210\|AX211' | awk '{print $1}') ; 
if [ "$pci_ids" == "" ]; then
	echo "* no find iax pciid, exit." ;
	exit -1 ;
fi
echo "* for pci_ids($pci_ids) $interval_us $chtype $macs" ;



#[function judge chtype]
#flq_chtype => rnf
if [ "$chtype" != "" ]; then
	declare -A rnf_map
	rnf_map=([NOHT]=0xc100 [HT20]=0xc200 [HT40]=0xca00 [HT40-]=0xca00 [HT40+]=0xca00 \
		[VHT20]=0xc300 [VHT40]=0xcb00 [VHT40-]=0xcb00 [VHT40+]=0xcb00 [VHT80]=0xd300 \
		[VHT160]=0xdb00 \
		[HE20]=0x11c400 [HE40]=0x11cc00 [HE40-]=0x11cc00 [HE40+]=0x11cc00 \
		[HE80]=0x11d400 [HE160]=0x11dc00)
	rnf_keys=${!rnf_map[*]}
	rnf_vals=${rnf_map[*]}
	if [ "${rnf_map[$chtype]}" = "" ]; then
		echo "* err. invalid chtype: ($chtype)" ;
		echo "* valid chtype: ($rnf_keys)" ;
		exit -1 ;
	fi
	rnf=${rnf_map[$chtype]}

	rnf=$((rnf - 0xc000)) ;
	ant_a=$((1<<14)) ;
	ant_b=$((1<<15)) ;
	rnf=$((rnf | ant_a)) ;
	#rnf=$((rnf | ant_b)) ;
	printf "* rnf %#x\n" $rnf ;
fi


#[function activate]
for pci_id in ${pci_ids[@]}; do
	dbgfs_dir=/sys/kernel/debug/iwlwifi/$pci_id/iwlmvm/ ;
	echo "* for $dbgfs_dir";

	# interval us
	echo $interval_us | sudo tee $dbgfs_dir/csi_interval > /dev/null ;

	# rnf
	if [ "$rnf" != "" ]; then
		echo $rnf | sudo tee $dbgfs_dir/monitor_tx_rate > /dev/null ;
	fi

	# filter macs
	#if [ "$macs" != "" ]; then; fi
	echo $macs | sudo tee $dbgfs_dir/csi_addresses > /dev/null ;

	# csi enable
	echo 1 | sudo tee $dbgfs_dir/csi_enabled > /dev/null ;
done

exit 0 ;

