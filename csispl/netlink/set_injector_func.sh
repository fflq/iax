
set_injector_func() {
	if [ $# -lt 3 ]; then
		echo "error inj_wal" ;
		return ;
	fi
	echo "set $1 injector $2 $3" ;
## inject
	wlan=$1 
	chn=$2
	bw=$3
    ifconfig $wlan 2>/dev/null 1>/dev/null
    while [ $? -ne 0 ]
    do
	    ifconfig $wlan 2>/dev/null 1>/dev/null
	    sleep 1
    done
    ifconfig $wlan down
    iw dev $wlan interface add inj0 type monitor
#ifconfig $wlan up
	ifconfig inj0 up
	iw inj0 set channel $chn $bw

}







