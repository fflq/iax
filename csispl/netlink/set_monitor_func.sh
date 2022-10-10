
set_monitor_func() {
	if [ $# -lt 3 ]; then
		echo "error mon_wal" ;
		return ;
	fi
	echo "set $1 monitor $2 $3" ;
## inject
	wlan=$1 
	chn=$2
	bw=$3
    ifconfig $wlan monitor 2>/dev/null 1>/dev/null
    while [ $? -ne 0 ]
    do
	    ifconfig $wlan monitor 2>/dev/null 1>/dev/null
	    sleep 1
    done
    ifconfig $wlan down
	iw $wlan set channel $chn $bw
    ifconfig $wlan up

}







