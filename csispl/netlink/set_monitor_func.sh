set -x ;

set_monitor_func() {
	if [ $# -lt 3 ]; then
		echo "error mon_wal" ;
		return ;
	fi
	wlan=$1 
	chn=$2
	bw=$3

	echo "set monitor $wlan $chn $bw" ;
	#setmode: need ($wlan down) 
    iwconfig $wlan mode monitor 2>/dev/null 1>/dev/null
    while [ $? -ne 0 ]
    do
	    sleep 1
		ifconfig $wlan down
	    iwconfig $wlan mode monitor 2>/dev/null 1>/dev/null
    done
	service network-manager stop
    ifconfig $wlan up
	# setchannel: noneed (monitor), need ($wlan up) (network-manager stop,maynoneed)
	iw $wlan set channel $chn $bw
}







