#!/usr/bin/sudo /bin/bash
#set -x ;

#params: wlp8s0 40 HT20 100 1:1:1:1:1:1 2:2:2:2:2:2

tools_dir=$(dirname ${BASH_SOURCE[0]})

echo "* $0 $*"

echo "" 
sudo ${tools_dir}/set-monitor.sh $*
if [ $? -ne 0 ]; then
	exit -1 ;
fi

shift;
shift;
echo "" 
sudo ${tools_dir}/iaxcsi-activate.sh $*
if [ $? -ne 0 ]; then
	exit -1 ;
fi


echo ""
echo "* set succ"
exit 0 ;
