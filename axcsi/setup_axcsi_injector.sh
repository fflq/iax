#!/usr/bin/sudo /bin/bash
#set -x ;


echo "* $0 $*"

echo "" 
sudo ./setup_monitor.sh $*
if [ $? -ne 0 ]; then
	exit -1 ;
fi

echo "" 
#sudo ./activate.sh 1000 $3 00:16:ea:12:34:56
sudo ./activate.sh 0 $3 00:16:ea:12:34:56
if [ $? -ne 0 ]; then
	exit -1 ;
fi


echo ""
echo "* setup succ"
exit 0 ;



