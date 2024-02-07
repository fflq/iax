#!/usr/bin/sudo /bin/bash
set -x;


unamer=$(uname -r)
unamer=4.2.0-16-generic


# others
sudo sed -i "s/archive.ubuntu.com/old-releases.ubuntu.com/g" /etc/apt/sources.list
sudo sed -i "s/security.ubuntu.com/old-releases.ubuntu.com/g" /etc/apt/sources.list
sudo apt update
git config --global user.name fflq
git config --global user.email flqnerve@163.com
echo "* need put id_rsa"
sudo chmod 0400 ~/.ssh/id_rsa
#git clone git@github.com:fflq/CSI.git
#matlab comps: instrument, signal proc, stat


# env
sudo apt-get install gcc make linux-headers-${unamer} git-core -y
sudo apt-get install iw -y


# csitool
CSITOOL_KERNEL_TAG=csitool-$(echo ${unamer} | cut -d . -f 1-2)
csitool_tag_tgz=${CSITOOL_KERNEL_TAG}.tar.gz
csitool_dir=linux-80211n-csitool-${CSITOOL_KERNEL_TAG}
if [ ! -e ${csitool_dir} ]; then
	echo "* no ${csitool_dir}"
	#git clone https://github.com/dhalperi/linux-80211n-csitool.git
	#cd linux-80211n-csitool
	#git checkout ${CSITOOL_KERNEL_TAG}
	if [ ! -e ${csitool_tag_tgz} ]; then
		echo "* no ${csitool_tag_tgz}"
		wget https://github.com/dhalperi/linux-80211n-csitool/archive/refs/tags/${csitool_tag_tgz}
	fi
	tar -xvf ${csitool_tag_tgz}
fi
cd ${csitool_dir}

make -C /lib/modules/${unamer}/build M=$(pwd)/drivers/net/wireless/iwlwifi modules
sudo make -C /lib/modules/${unamer}/build M=$(pwd)/drivers/net/wireless/iwlwifi INSTALL_MOD_DIR=updates modules_install
sudo depmod
cd ..


# csitool-sup
if [ ! -e linux-80211n-csitool-supplementary ]; then
git clone https://github.com/dhalperi/linux-80211n-csitool-supplementary.git
fi
for file in /lib/firmware/iwlwifi-5000-*.ucode; do sudo mv $file $file.orig; done
sudo cp linux-80211n-csitool-supplementary/firmware/iwlwifi-5000-2.ucode.sigcomm2010 /lib/firmware/
sudo ln -s iwlwifi-5000-2.ucode.sigcomm2010 /lib/firmware/iwlwifi-5000-2.ucode
sudo ln -s iwlwifi-5000-2.ucode.sigcomm2010 /lib/firmware/iwlwifi-5000-5.ucode


echo "*** go on ?"
read a

# log csi
sudo modprobe -r iwldvm iwlwifi mac80211
sudo modprobe iwlwifi connector_log=0x1
#make -C linux-80211n-csitool-supplementary/netlink
#sudo linux-80211n-csitool-supplementary/netlink/log_to_file csi.dat



