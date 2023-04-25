#!/bin/bash

cleans=(\
	"atheros/Atheros-CSI-Tool-UserSpace-APP/recvCSI" \
	"atheros/Atheros-CSI-Tool-UserSpace-APP/sendData" \
	"intel5300/csispl/injection" "intel5300/csispl/netlink" \
	"axcsi/csist/cpp/" \
);

for d in ${cleans[@]}; do
	echo "* make clean $d" ;
	make -C $d clean ;
done

