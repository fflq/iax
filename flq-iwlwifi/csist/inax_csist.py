#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from realtime_ploter import realtime_ploter

from pyflqcsi.flqcsi_pool import flqcsi_pool
from pyflqcsi.flqcsi import flqcsi, flqcsi_st, flqcsi_type


def plot_mag(csist: flqcsi_st):
    plt.figure(1)
    for i in range(csist.nrx):
        sns.lineplot(np.abs(csist.csi[0,i]))


def plot_cir(csist: flqcsi_st):
    cfr = csist.csi[0] 
    cir = np.fft.ifft(cfr)
    #sameto, cir = np.array([cir1, cir2])
    cir = cir[:,0:20]
    dt = 1e9 / (csist.chan_width * 1e6) #ns
    xs = np.arange(0, cir.shape[1])*dt 
    #i = np.argmax(np.real(cir)) 
    #print("t({}) d({})".format(xs[i], xs[i]*0.3))
    sns.lineplot(x=xs, y=np.abs(cir[0]))
    sns.scatterplot(x=xs, y=np.abs(cir[0]))
    sns.lineplot(x=xs, y=20+np.abs(cir[1]))
    sns.scatterplot(x=xs, y=20+np.abs(cir[1]))
    #input()
     

#grp = realtime_ploter(9)
def plot_breath(csist: flqcsi_st):
    csi = csist.csi
    s = np.mean(np.abs(csi[0,1] * np.conj(csi[0,0])))
    #s = np.mean(np.angle(csi[0,1] * np.conj(csi[0,0])))
    grp.add_points(s)


grp8 = realtime_ploter(8)
def plot_attack(csist: flqcsi_st):
    avgmag = (np.mean(np.abs(csist.csi[0,0])) + np.mean(np.abs(csist.csi[0,1]))) / 2 
    avgmag = (np.abs(csist.csi[0,0,0]) + np.abs(csist.csi[0,1,0])) / 2 
    grp8.add_points(avgmag, move_axis=False)


def csist_filter(csist:flqcsi_st):
    if csist is None:
        return False
    return True
    if not csist.smac.startswith("0:16:ea:12:34:56"):
        return False

    print("*******************")
    return True


gn = 0
def csist_callback(csist: flqcsi_st):
    if not csist_filter(csist):
        return

    global gn
    gn = gn + 1
    ranges = [500, 1600]
    if (gn < ranges[0] or gn > ranges[1]):
        pass
        #return

    #plot_mag(csist)
    #plot_breath(csist)
    plot_attack(csist)
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
