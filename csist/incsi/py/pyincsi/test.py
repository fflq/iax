#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
sys.path.append(os.path.pardir)

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from pyincsi.incsi_st import incsi_st
from pyincsi.incsi_file import incsi_file
from pyincsi.incsi_netlink import incsi_netlink


def plot_mag(csist: incsi_st):
    for i in range(csist.nrx):
        sns.lineplot(np.abs(csist.csi[0,i]))


def csist_callback(csist: incsi_st):
    plot_mag(csist)
    plt.pause(0.1)


incsi_netlink(savepath=None, csist_callback=csist_callback).start()
plt.show()
