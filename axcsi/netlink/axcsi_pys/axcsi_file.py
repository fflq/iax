#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import struct
import os

from axcsi_st import axcsi_st


class axcsi_file:
    csipath = None
    csist_callback = None
    
    def __init__(self, csipath, csist_callback):
        self.csipath = csipath
        self.csist_callback = csist_callback


    def start(self):
        with open(self.csipath, 'rb') as f:
            self.read_axcsi_file(f)
            

    def read_axcsi_file(self, f):
        n = 0
        while True:
            n4 = f.read(4)
            if n4 == b'':
                break
            csi_hdr_len = struct.unpack('>i', n4)[0]
            if csi_hdr_len != 272:
                raise RuntimeError('fread csi_hdr_len(%d)!=272' % (csi_hdr_len))
            csi_hdr = f.read(csi_hdr_len)

            csi_data_len = struct.unpack('>i', f.read(4))[0]
            csi_data = f.read(csi_data_len)

            if self.csist_callback:
                self.csist_callback(axcsi_st(csi_hdr, csi_data).csist)

            n = n + 1
            print('* this csi no.%d\n' % (n))
