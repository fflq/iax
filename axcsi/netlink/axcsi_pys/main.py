#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

import axcsi


def calib_csi(tones, chan_type_str):
    #print(tones[axcsi.subcidxs[chan_type_str]])
    xs = range(0,len(tones))
    print(xs)
    csi = np.interp(xs, xs, tones)
    return csi


def plot_mag(csist):
    csi = csist.csi[0,0,:]
    print(csi)
    sns.lineplot(abs(csi))
    plt.pause(0.01)
    csi = calib_csi(csi*2, csist.chan_type_str)
    print(csi)
    sns.lineplot(abs(csi))
    #plt.pause(0.01)
    plt.show()

def plot_phase(csist):
    csi = calib_csi(csist.csi[0,0,:], csist.chan_type_str)
    phases = np.unwrap(np.angle(csi))
    sns.lineplot(phases)
    #plt.pause(0.01)


def csist_callback(csist):
    #plot_mag(csist)
    plot_phase(csist)

    
axcsi.run_axcsi(sys.argv[1], sys.argv[2], csist_callback)

