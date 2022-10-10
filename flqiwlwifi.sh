#!/bin/bash

make -C /lib/modules/$(uname -r)/build M=$(pwd)/drivers/net/wireless/iwlwifi modules
#make -C /lib/modules/$(uname -r)/build M=$(pwd)/drivers/base modules

sudo make -C /lib/modules/$(uname -r)/build M=$(pwd)/drivers/net/wireless/iwlwifi INSTALL_MOD_DIR=updates  modules_install
#sudo make -C /lib/modules/$(uname -r)/build M=$(pwd)/drivers/base INSTALL_MOD_DIR=updates  modules_install
sudo depmod
