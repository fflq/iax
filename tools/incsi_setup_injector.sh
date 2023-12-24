#!/usr/bin/sudo /bin/bash
#set -x ;

#chn 40 cant, 64 can

tools_dir=$(dirname ${BASH_SOURCE[0]})

echo "* $0 $*"

echo "" 
sudo ${tools_dir}/setup_monitor.sh $*
if [ $? -ne 0 ]; then
	exit -1 ;
fi

echo "" 
sudo ${tools_dir}/incsi_activate.sh $3 
if [ $? -ne 0 ]; then
	exit -1 ;
fi


echo ""
echo "* setup succ"
exit 0 ;



