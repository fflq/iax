#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

import axcsi
from axcsi import CSIST


def plot_mag(csist: CSIST):
    #sns.lineplot(abs(csist.raw_csi[0,0,:])-10)
    #sns.lineplot(y=abs(csist.raw_csi[0,0,:])-10, x=csist.subc.data_pilot_subcs)
    sns.lineplot(y=abs(csist.csi[0,0,:]), x=csist.subc.data_pilot_dc_subcs)
    plt.pause(0.01); 
    #input('-')
    #plt.show()

def plot_phase(csist: CSIST):
    raw_csi = csist.raw_csi[0,0,:]
    csi = csist.csi[0,0,:]
    phases = np.unwrap(np.angle(csi))
    sns.lineplot(phases)
    #plt.pause(0.01)


def csist_callback(csist: CSIST):
    plot_mag(csist)
    #plot_phase(csist)
    return 0

    
axcsi.run_axcsi(sys.argv[1], sys.argv[2], csist_callback)

