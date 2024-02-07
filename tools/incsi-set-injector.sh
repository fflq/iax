#!/usr/bin/sudo /bin/bash
#set -x ;

#chn 40 cant, 64 can

tools_dir=$(dirname ${BASH_SOURCE[0]})

echo "* $0 $*"

echo "" 
sudo ${tools_dir}/set-monitor.sh $*
if [ $? -ne 0 ]; then
	exit -1 ;
fi

echo "" 
sudo ${tools_dir}/incsi-activate.sh $3 
if [ $? -ne 0 ]; then
	exit -1 ;
fi


echo ""
echo "* set succ"
exit 0 ;
