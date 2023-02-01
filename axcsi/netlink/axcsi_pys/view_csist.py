#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from axcsi_netlink import axcsi_netlink
from axcsi_file import axcsi_file
from axcsi_st import csi_st


def plot_mag(csist: csi_st):
    #sns.lineplot(abs(csist.csi[0,0,:])-10)
    sns.lineplot(y=abs(csist.csi[0,0,:])-10, x=csist.subc.data_pilot_subcs)
    sns.lineplot(y=abs(csist.scsi[0,0,:]), x=csist.subc.data_pilot_dc_subcs)
    plt.pause(0.01); 
    #input('-')
    #plt.show()

def plot_phase(csist: csi_st):
    raw_csi = csist.raw_csi[0,0,:]
    csi = csist.csi[0,0,:]
    phases = np.unwrap(np.angle(csi))
    sns.lineplot(phases)
    #plt.pause(0.01)


def csist_callback(csist: csi_st):
    plot_mag(csist)
    #plot_phase(csist)
    return 0

    
if sys.argv[1] == 'file':
    axcsi_file(sys.argv[2], csist_callback).start()
else:
    axcsi_netlink(sys.argv[1], sys.argv[2], csist_callback).start()
input('end')
