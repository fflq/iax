#!/bin/bash
# can not cancel csi set, has change firmware and driver
# use eg.seeyout_5G without password to connect internet

ln -sf /lib/firmware/iwlwifi-5000-5.ucode.orig /lib/firmware/iwlwifi-5000-2.ucode
ls -l /lib/firmware/iwlwifi-5000-*

modprobe -r iwlwifi
modprobe iwlwifi
