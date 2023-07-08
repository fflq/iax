#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from pyflqcsi.flqcsi_pool import flqcsi_pool
from pyflqcsi.flqcsi import flqcsi, flqcsi_st, flqcsi_type


def plot_mag(csist: flqcsi_st):
    for i in range(csist.nrx):
        sns.lineplot(np.abs(csist.csi[0,i]))

fig, ax = plt.subplots()
line, = ax.plot([], [], '-o')
ax.set_xlim(-10, 10)
def plot_breath(csist: flqcsi_st):



def csist_callback(csist: flqcsi_st):
    plot_mag(csist)
    plot_breath(csist)
    plt.pause(0.01)


if len(sys.argv) < 4:
    print("* usage: {} iax/in file/wlan csipath/mon0 savepath.".format(sys.argv[0]))
    exit(0)


csi_type = flqcsi_type.IAXCSI_TYPE
if sys.argv[1] != "iax":
    csi_type = flqcsi_type.INCSI_TYPE

wlan = None
csipath = None
file_not_netlink = True
if sys.argv[2] == "file":
    csipath = sys.argv[3]
    file_not_netlink = True
else:
    wlan = sys.argv[3]
    file_not_netlink = False

savepath = None
if len(sys.argv) > 4:
    savepath = sys.argv[4]


flqcsi(csi_type=csi_type, file_not_netlink=file_not_netlink, 
       wlan=wlan, csipath=csipath, savepath=savepath, 
       csist_callback=csist_callback).start()

plt.show()

exit(0)


flqcsi_pool([
    flqcsi(flqcsi_type.INCSI_TYPE, False, savepath=None,
       csist_callback=csist_callback),
    flqcsi(flqcsi_type.INCSI_TYPE, True, csipath=in_csipath,
       csist_callback=csist_callback),
]).start()

plt.show()
