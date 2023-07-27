#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from pyflqcsi.flqcsi_pool import flqcsi_pool
from pyflqcsi.flqcsi import flqcsi, flqcsi_st, flqcsi_type


def plot_mag(csist: flqcsi_st):
    plt.figure(1)
    for i in range(csist.nrx):
        sns.lineplot(np.abs(csist.csi[0,i]))


class realtime_ploter:
    def __init__(self, fid=1, max_display_size=100):
        self.fid = fid
        self.max_display_size = max_display_size
        self.fig, self.ax = plt.subplots()
        self.xs = []
        self.ys = []
        self.line = self.ax.plot(self.xs, self.ys, '-o', lw=2, marker='.')[0]
        self.yranges = [0, 0]
        self.idx = -1
        plt.tight_layout()

    def add_points(self, y, x = None):
        if x == None:
            x = 1
            if (len(self.xs) > 0):
                x = self.xs[-1] + 1

        self.xs.append(x)
        self.ys.append(y)
        self.idx = self.idx + 1
    
        #select ranges
        #ys_norm = self.ys / np.linalg.norm(self.ys)
        ys_norm = (self.ys - np.mean(self.ys)) / np.std(self.ys)
        ys_norm = self.ys
        self.line.set_data(self.xs, ys_norm)
        #self.line.set_data(self.xs, self.ys)

        ixb, ixe = max(0, self.idx - self.max_display_size), self.idx
        #ixb, ixe = 0, -1
        self.ax.set_xlim(self.xs[ixb], self.xs[ixe])
        yreds = abs(max(self.ys)) * 0.2 + 10
        self.ax.set_ylim(min(self.ys)-yreds, max(self.ys)+yreds)
        #self.ax.set_ylim(-5, 5)

        #truncate(when all/2 blocks full, truncate first block)
        #cache more data for norm
        if self.idx > 100*self.max_display_size:
            self.idx = self.idx - self.max_display_size
            self.xs = self.xs[self.max_display_size:]
            self.ys = self.ys[self.max_display_size:]
        #print(self.xs)

        #plt.pause(0.01)
        


grp = realtime_ploter(9)
def plot_breath(csist: flqcsi_st):
    csi = csist.csi
    s = np.mean(np.abs(csi[0,1] * np.conj(csi[0,0])))
    #s = np.mean(np.angle(csi[0,1] * np.conj(csi[0,0])))
    grp.add_points(s)


gn = 0
def csist_callback(csist: flqcsi_st):
    global gn
    gn = gn + 1
    ranges = [1000, 2000]
    if (gn < ranges[0] or gn > ranges[1]):
        pass
        #return

    #plot_mag(csist)
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
