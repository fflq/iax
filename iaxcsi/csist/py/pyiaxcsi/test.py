#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
sys.path.append(os.path.pardir)

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from pyiaxcsi.iaxcsi_st import iaxcsi_st
from pyiaxcsi.iaxcsi_netlink import iaxcsi_netlink


def plot_mag(csist: iaxcsi_st):
    for i in range(csist.nrx):
        sns.lineplot(np.abs(csist.csi[0,i]))


def csist_callback(csist: iaxcsi_st):
    plot_mag(csist)
    plt.pause(0.1)


iaxcsi_netlink(wlan="wlp8s0mon0", savepath=None, csist_callback=csist_callback).start()
plt.show()
