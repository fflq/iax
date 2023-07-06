#!/usr/bin/sudo /bin/bash
#set -x ;


echo "* $0 $*"

echo "" 
sudo ./setup_monitor.sh $*
if [ $? -ne 0 ]; then
	exit -1 ;
fi

echo "" 
sudo ./iaxcsi_activate.sh $3 10000 ""
if [ $? -ne 0 ]; then
	exit -1 ;
fi


echo ""
echo "* setup succ"
exit 0 ;



