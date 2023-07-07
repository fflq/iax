#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from enum import Enum

from pyi53csi import i53csi_st
from pyi53csi.i53csi import i53csi

from pyiaxcsi import iaxcsi_st 
from pyiaxcsi.iaxcsi import iaxcsi


class flqcsi_st:
    nrx: int; ntx: int; ntone: int;
    bw:int; us: int; seq: int; noise: int; agc: int; rate: int;
    chan_type_str: str; smac: str; dmac: str;
    rssis: np.array
    perm: np.array
    subcs: np.array
    #tx*rx*tone
    csi: np.array


class csi_type_enum(Enum):
    I53CSI_TYPE = 1
    IAXCSI_TYPE = 2


class flqcsi:
    csist: flqcsi_st = None

    wlan: str = None
    csipath: str = None
    savepath: str = None
    csist_callback = None
    csi_type: csi_type_enum
    file_no_netlink = True

    i53csi_handler: i53csi = None
    iaxcsi_handler: iaxcsi_handler = None


    def __init__(self, csi_type: csi_type_enum, file_not_netlink=True, wlan=None, csipath=None, savepath=None, csist_callback=None):
        self.wlan = wlan
        self.csipath = csipath
        self.savepath = savepath
        self.csist_callback = csist_callback
        self.csi_type = csi_type
        self.file_no_netlink = file_not_netlink

        if (self.csi_type == csi_type.IAXCSI_TYPE):
            self.iaxcsi_handler = iaxcsi(wlan=self.wlan, csipath=self.csipath, csist_callback=self.iaxcsist_callback)
        else:
            self.i53csi_handler = i53csi(csipath=self.csipath, savepath=self.savepath, csist_callback=self.i53csist_callback)


    def convert_i53csist_to_flqcsist(i53csist: i53csi_st.csi_st):
        flqcsist = flqcsi_st()
        flqcsist.rssis = np.array([i53csist.rssi_a, i53csist.rssi_b, i53csist.rssi_c])
        flqcsist.nrx = i53csist.nrx
        flqcsist.ntx = i53csist.ntx
        flqcsist.ntone = i53csist.ntone
        flqcsist.agc = i53csist.agc
        flqcsist.noise = i53csist.noise
        flqcsist.perm = i53csist.perm
        flqcsist.us = i53csist.timestamp_low
        flqcsist.seq = i53csist.bfee_count
        flqcsist.rate = i53csist.rate
        #flqcsist.bw = ?
        #flqcsist.subcs = ?
        flqcsist.csi = i53csist.csi
        return flqcsist


    def i53csist_callback(self, i53csist: i53csi_st.csi_st):
        if (self.csist_callback):
            self.csist_callback(self.convert_i53csist_to_flqcsist(i53csist))


    def convert_iaxcsist_to_flqcsist(iaxcsist: iaxcsi_st.csi_st):
        flqcsist = flqcsi_st()
        flqcsist.rssis = np.array([iaxcsist.rssi1, iaxcsist.rssi2])
        flqcsist.nrx = iaxcsist.nrx
        flqcsist.ntx = iaxcsist.ntx
        flqcsist.ntone = iaxcsist.nstone
        flqcsist.seq = iaxcsist.seq
        flqcsist.perm = iaxcsist.perm
        flqcsist.us = iaxcsist.timestamp_low
        flqcsist.smac = iaxcsist.smac
        flqcsist.rate = iaxcsist.rnf
        flqcsist.bw = iaxcsist.chan_width
        flqcsist.chan_type_str = iaxcsist.chan_type_str
        flqcsist.subcs = iaxcsist.subc.subcs

        flqcsist.csi = np.zeros([flqcsist.ntx, flqcsist.nrx, flqcsist.ntone])
        for itx in range(flqcsist.itx):
            for irx in range(flqcsist.irx):
                flqcsist.csi[itx,irx] = iaxcsist.scsi[irx,itx]
 

    def iaxcsist_callback(self, iaxcsist: iaxcsi_st):
        if (self.csist_callback):
            self.csist_callback(self.convert_iaxcsist_to_flqcsist(iaxcsist))


