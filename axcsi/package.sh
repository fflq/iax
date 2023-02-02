#!/bin/bash 
set -x 

dt=$(date +'%Y%m%d')
src_dir=.
pack_name=axcsi_package_${dt}
pack_dir=/tmp/
dst_dir=/tmp/$pack_name


rm -rf $dst_dir
mkdir -p $dst_dir
cp $src_dir/run_in_package.sh $dst_dir/run.sh
cp $src_dir/activate.sh $dst_dir
cp $src_dir/setup_monitor.sh $dst_dir
cp $src_dir/setup_axcsi_monitor.sh $dst_dir
cp $src_dir/setup_axcsi_injector.sh $dst_dir
cp $src_dir/connwifi.sh $dst_dir
cp $src_dir/sources.list $dst_dir


cp -rf $src_dir/flq-backport-iwlwifi-debug/flq-backport-iwlwifi $dst_dir/.flq-backport-iwlwifi
make clean -C $dst_dir/.flq-backport-iwlwifi
$dst_dir/.flq-backport-iwlwifi/clean.sh


cp -rf $src_dir/flq-backport-iwlwifi-debug/flq-linux-firmware $dst_dir/


cp -rf $src_dir/injection $dst_dir/
make clean -C $dst_dir/injection
make clean -C $dst_dir/injection/lorcon-old


mkdir -p $dst_dir/csi
netlink_files=(axcsi.cpp axcsi.h iwl_fw_api_rs.h Makefile)
for f in ${netlink_files[@]}
do
	cp -rf $src_dir/csist/cpp/$f $dst_dir/csi/
done
script_files=(read_axcsi.m)
for f in ${script_files[@]}
do
	cp -rf $src_dir/csist/matlab/$f $dst_dir/csi/
done


cd $pack_dir
tar -zcf $pack_name.tgz $pack_name 



