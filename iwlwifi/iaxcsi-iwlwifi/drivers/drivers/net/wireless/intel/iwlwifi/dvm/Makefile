# SPDX-License-Identifier: GPL-2.0
# DVM
obj-$(CONFIG_IWLDVM)	+= iwldvm.o
iwldvm-objs		+= main.o rs.o mac80211.o ucode.o tx.o
iwldvm-objs		+= lib.o calib.o tt.o sta.o rx.o

iwldvm-objs		+= power.o
iwldvm-objs		+= scan.o
iwldvm-objs		+= rxon.o devices.o

iwldvm-$(CONFIG_IWLWIFI_LEDS) += led.o
iwldvm-$(CONFIG_IWLWIFI_DEBUGFS) += debugfs.o

#fflqb_csi_53
iwldvm-y += connector.o
#fflqe

#fflqb_dvm
#ccflags-y += -I $(srctree)/$(src)/../
ccflags-y += -I$(src)/../
#fflqe

