#!/usr/bin/sudo /bin/bash
#set -x ;

#params: wlp8s0 40 HT20 

tools_dir=$(dirname ${BASH_SOURCE[0]})

echo "* $0 $*"

echo "" 
sudo ${tools_dir}/set-monitor.sh $*
if [ $? -ne 0 ]; then
	exit -1 ;
fi

echo "" 
sudo ${tools_dir}/iaxcsi-activate.sh $3 0 00:16:ea:12:34:56
if [ $? -ne 0 ]; then
	exit -1 ;
fi


echo ""
echo "* set succ"
exit 0 ;
