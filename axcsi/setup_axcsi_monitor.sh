#!/usr/bin/sudo /bin/bash
#set -x ;


echo "* $0 $*"

echo "" 
sudo ./setup_monitor.sh $*
if [ $? -ne 0 ]; then
	exit -1 ;
fi

echo "" 
sudo ./activate.sh 100000 $3 ""
if [ $? -ne 0 ]; then
	exit -1 ;
fi


echo ""
echo "* setup succ"
exit 0 ;



