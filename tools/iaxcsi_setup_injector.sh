#!/usr/bin/sudo /bin/bash
#set -x ;

tools_dir=$(dirname ${BASH_SOURCE[0]})

echo "* $0 $*"

echo "" 
sudo ${tools_dir}/setup_monitor.sh $*
if [ $? -ne 0 ]; then
	exit -1 ;
fi

echo "" 
sudo ${tools_dir}/iaxcsi_activate.sh $3 0 00:16:ea:12:34:56
if [ $? -ne 0 ]; then
	exit -1 ;
fi


echo ""
echo "* setup succ"
exit 0 ;



