#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from pyflqcsi.flqcsi import flqcsi, flqcsi_st


def plot_mag(csist: flqcsi_st):
    for i in range(csist.nrx):
        sns.lineplot(np.abs(csist.csi[0,i]))


def csist_callback(csist: flqcsi_st):
    plot_mag(csist)
    plt.pause(0.1)


flqcsi(csi_type=flqcsi.csi_type.I53CSI_TYPE, file_not_netlink=True, csipath='/tmp/s', csist_callback=csist_callback)
plt.show()
