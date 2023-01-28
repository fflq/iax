#!/usr/bin/sudo /bin/bash
#set -x ;



#[function usage]
if [ $# -ge 1 ] && [ "$1" = "-h" ]; then
echo "Usage: $0 [interval_us] [chtype] [macs]" 
echo " - interval_us: recv csi interval"
echo " - chtype: chtype for inject rate. eg. HT20 VHT40 HE160"
echo " - macs: filtered macs"
echo " * eg: $0 10000 VHT40- 00:16:ea:12:34:56"
echo ""
exit ;
fi



#[function handle args]
interval_us=10000
chtype=NOHT
mac=00:16:ea:12:34:56

if [ $# -ge 1 ]; then
	interval_us=$1 ;
	shift
fi
if [ $# -ge 1 ]; then
	chtype=$1 ;
	shift
fi
if [ $# -ge 1 ]; then
	macs=$* ;
fi



#[function get_pci]
pci=$(lspci -D | grep '2725\|210' | awk '{print $1}') ; 
if [ "$pci" == "" ]; then
	echo "* no find ax210 pciid, exit." ;
	exit -1 ;
fi
echo "* for pci($pci) $interval_us $chtype $macs" ;



#[function judge chtype]
#flq_chtype => rnf
declare -A rnf_map
rnf_map=([NOHT]=0xc100 [HT20]=0xc200 [HT40]=0xca00 [HT40-]=0xca00 [HT40+]=0xca00 \
	[VHT20]=0xc300 [VHT40]=0xcb00 [VHT40-]=0xcb00 [VHT40+]=0xcb00 [VHT80]=0xd300 [VHT160]=0xdb00 \
	[HE20]=0x11c400 [HE40]=0x11cc00 [HE40-]=0x11cc00 [HE40+]=0x11cc00 [HE80]=0x11d400 [HE160]=0x11dc00)
rnf_keys=${!rnf_map[*]}
rnf_vals=${rnf_map[*]}
if [ "${rnf_map[$chtype]}" = "" ]; then
	echo "* err. invalid chtype: ($chtype)" ;
	echo "* valid chtype: ($rnf_keys)" ;
	exit -1 ;
fi
rnf=${rnf_map[$chtype]}



#[function activate]
mvm_dbgfs_dir=/sys/kernel/debug/iwlwifi/$pci/iwlmvm/ ;

# interval us
echo $interval_us | sudo tee $mvm_dbgfs_dir/csi_interval > /dev/null ;

# rnf
echo $rnf | sudo tee $mvm_dbgfs_dir/flq_monitor_tx_rate > /dev/null ;

# filter macs
if [ "$macs" != "" ]; then
	echo $macs | sudo tee $mvm_dbgfs_dir/csi_addresses > /dev/null ;
fi

# csi enable
echo 1 | sudo tee $mvm_dbgfs_dir/csi_enabled > /dev/null ;


exit 0 ;

