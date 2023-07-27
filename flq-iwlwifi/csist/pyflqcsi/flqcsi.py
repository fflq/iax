#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
#pyincsi and pyiaxcsi are indeps, so only addpath, 
#not make pyiaxcsi.* change to pyflqcsi.pyiaxcsi.iaxcsi
curdir = os.path.dirname(os.path.abspath(__file__))
if os.path.exists(curdir) :
    sys.path.append(curdir)

import numpy as np
from enum import Enum
import threading

from pyflqcsi.pyincsi import incsi_st
from pyflqcsi.pyincsi.incsi import incsi

from pyflqcsi.pyiaxcsi import iaxcsi_st 
from pyflqcsi.pyiaxcsi.iaxcsi import iaxcsi


class flqcsi_st:
    nrx: int; ntx: int; ntone: int;
    bw:int; us: int; seq: int; noise: int; agc: int; rate: int;
    chan_type_str: str; smac: str; dmac: str;
    rssis: np.array
    perm: np.array
    subcs: np.array
    #tx*rx*tone
    csi: np.array

    csi_type: int


class flqcsi_type(Enum):
    INCSI_TYPE = 1
    IAXCSI_TYPE = 2


class flqcsi:
    csist: flqcsi_st = None

    wlan: str = None
    csipath: str = None
    savepath: str = None
    csist_callback = None
    csi_type: flqcsi_type
    file_no_netlink = True

    incsi_handler: incsi = None
    iaxcsi_handler: iaxcsi = None


    def __init__(self, csi_type: flqcsi_type, file_not_netlink=True, wlan=None, csipath=None, savepath=None, csist_callback=None):
        self.wlan = wlan
        self.csipath = csipath
        self.savepath = savepath
        self.csist_callback = csist_callback
        self.csi_type = csi_type
        self.file_no_netlink = file_not_netlink

        if (self.csi_type == csi_type.IAXCSI_TYPE):
            self.iaxcsi_handler = iaxcsi(wlan=self.wlan, csipath=self.csipath, savepath=self.savepath, csist_callback=self.iaxcsist_callback)
        else:
            self.incsi_handler = incsi(csipath=self.csipath, savepath=self.savepath, csist_callback=self.incsist_callback)

        print(self.__dict__)


    def start(self):
        if self.incsi_handler:
            self.incsi_handler.start()

        if self.iaxcsi_handler:
            self.iaxcsi_handler.start()

    
    def async_start(self):
        t = threading.Thread(target=self.start)
        t.start()
        return t


    def convert_incsist_to_flqcsist(self, incsist: incsi_st.csi_st):
        flqcsist = flqcsi_st()
        flqcsist.csi_type = self.csi_type
        flqcsist.rssis = np.array([incsist.rssi_a, incsist.rssi_b, incsist.rssi_c])
        flqcsist.ntx = incsist.ntx
        flqcsist.nrx = incsist.nrx
        flqcsist.ntone = incsist.ntone
        flqcsist.agc = incsist.agc
        flqcsist.noise = incsist.noise
        flqcsist.perm = incsist.perm
        flqcsist.us = incsist.timestamp_low
        flqcsist.seq = incsist.bfee_count
        flqcsist.rate = incsist.rate
        #flqcsist.bw = ?
        #flqcsist.subcs = ?
        print(flqcsist.__dict__)
        flqcsist.csi = incsist.csi
        return flqcsist


    def incsist_callback(self, incsist: incsi_st.csi_st):
        if (self.csist_callback and (incsist is not None)):
            self.csist_callback(self.convert_incsist_to_flqcsist(incsist))


    def convert_iaxcsist_to_flqcsist(self, iaxcsist: iaxcsi_st.csi_st):
        flqcsist = flqcsi_st()
        flqcsist.csi_type = self.csi_type
        flqcsist.rssis = np.array([iaxcsist.rssi1, iaxcsist.rssi2])
        flqcsist.ntx = iaxcsist.ntx
        flqcsist.nrx = iaxcsist.nrx
        flqcsist.ntone = iaxcsist.nstone
        flqcsist.seq = iaxcsist.seq
        flqcsist.perm = iaxcsist.perm
        flqcsist.us = iaxcsist.us
        flqcsist.smac = iaxcsist.smac
        flqcsist.rate = iaxcsist.rnf
        flqcsist.bw = iaxcsist.chan_width
        flqcsist.chan_type_str = iaxcsist.chan_type_str
        print(flqcsist.__dict__)
        flqcsist.subcs = iaxcsist.subc.subcs

        flqcsist.csi = np.zeros([flqcsist.ntx, flqcsist.nrx, flqcsist.ntone], dtype=complex)
        for itx in range(flqcsist.ntx):
            for irx in range(flqcsist.nrx):
                flqcsist.csi[itx,irx] = iaxcsist.scsi[irx,itx]
        return flqcsist
 

    def iaxcsist_callback(self, iaxcsist: iaxcsi_st):
        if (self.csist_callback and (iaxcsist is not None)):
            self.csist_callback(self.convert_iaxcsist_to_flqcsist(iaxcsist))


