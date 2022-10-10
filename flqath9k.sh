#!/bin/bash

make -C /lib/modules/$(uname -r)/build M=$(pwd)/drivers/net/wireless/ath/ath9k modules
#make -C /lib/modules/$(uname -r)/build M=$(pwd)/drivers/base modules

sudo make -C /lib/modules/$(uname -r)/build M=$(pwd)/drivers/net/wireless/ath/ath9k INSTALL_MOD_DIR=updates  modules_install
#sudo make -C /lib/modules/$(uname -r)/build M=$(pwd)/drivers/base INSTALL_MOD_DIR=updates  modules_install
sudo depmod
