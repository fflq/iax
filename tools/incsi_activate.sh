#!/usr/bin/sudo /bin/bash
#set -x ;
#only for simo

#[function usage]
if [ $# -ge 1 ] && [ "$1" = "-h" ]; then
echo "Usage: $0 [ht40]" 
echo " - chtype: HT20/HT40"
echo " * eg: $0 HT40"
echo ""
exit ;
fi



#[function handle args]
chtype=HT20
if [ $# -ge 1 ]; then
	chtype=$1;
	shift
fi


#[function get_pci]
pci_ids=$(lspci -D | grep 'WiFi Link 5300' | awk '{print $1}') ; 
if [ "$pci_ids" == "" ]; then
	echo "* no find intel5300 pci_ids, exit." ;
	exit -1 ;
fi
echo "* for pci_ids($pci_ids) $chtype simo" ;


#[function judge chtype]
#rnf=0x4101, ant_a, 20+ht, rate
#rnf=0x4911, ant_a, 40+ht, siso, rate
#flq_chtype => rnf
if [ "$chtype" != "" ]; then
	bw20=0x4101;
	bw40=0x4901;
	declare -A rnf_map
	rnf_map=([NOHT]=$bw20 [HT20]=$bw20 [HT40]=$bw40 [HT40-]=$bw40 [HT40+]=$bw40); 
	rnf_keys=${!rnf_map[*]}
	rnf_vals=${rnf_map[*]}
	if [ "${rnf_map[$chtype]}" = "" ]; then
		echo "* err. invalid chtype: ($chtype)" ;
		echo "* valid chtype: ($rnf_keys)" ;
		exit -1 ;
	fi
	rnf=${rnf_map[$chtype]}

	printf "* %#x\n" $rnf ;
fi


#[function activate]
for pci_id in ${pci_ids[@]}; do
	dbgfs_dir=/sys/kernel/debug/iwlwifi/$pci_id/iwldvm/debug ;
	echo "* for $dbgfs_dir";

	# rnf
	if [ "$rnf" != "" ]; then
		echo $rnf | sudo tee $dbgfs_dir/monitor_tx_rate > /dev/null ;
	fi
done

exit 0 ;

