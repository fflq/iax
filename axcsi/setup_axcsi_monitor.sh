#!/usr/bin/sudo /bin/bash
#set -x ;


echo "* $0 $*"

echo "" 
sudo ./setup_monitor.sh $*
if [ $? -ne 0 ]; then
	exit -1 ;
fi

echo "" 
<<<<<<< HEAD
sudo ./activate.sh 100000 $3 ""
=======
sudo ./activate.sh 10000 
>>>>>>> 2821d0cf5b07413cdf4972d79128ca68625859f9
if [ $? -ne 0 ]; then
	exit -1 ;
fi


echo ""
echo "* setup succ"
exit 0 ;



