#!/usr/bin/sudo /bin/bash
#set -x ;


echo "* $0 $*"

echo "" 
sudo ./setup_monitor.sh $*
if [ $? -ne 0 ]; then
	exit -1 ;
fi

echo "" 
sudo ./iaxcsi_activate.sh $3 0 00:16:ea:12:34:56
if [ $? -ne 0 ]; then
	exit -1 ;
fi


echo ""
echo "* setup succ"
exit 0 ;



