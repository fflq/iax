#!/usr/bin/sudo /bin/bash
set -x ;

tools_dir=$(dirname ${BASH_SOURCE[0]})

bw=40
chtype=HT40-
reins=0

if [ $# -ge 1 ]; then
	bw=$1
	shift
fi

if [ $# -ge 1 ]; then
	chtype=$1
	shift
fi

if [ $# -ge 1 ]; then
	reins=1
	${tools_dir}/reins_csi_iwlwifi.sh
fi


${tools_dir}/incsi_setup_injector.sh wlp7s0 $bw $chtype 
${tools_dir}/iaxcsi_setup_injector.sh wlp8s0 $bw $chtype 

