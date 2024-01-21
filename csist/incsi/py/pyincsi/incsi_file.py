#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import struct

from pyincsi.incsi_st import incsi_st


class incsi_file:
    csipath = None
    csist_callback = None
    
    def __init__(self, csipath, csist_callback=None):
        self.csipath = csipath
        self.csist_callback = csist_callback


    def start(self):
        with open(self.csipath, 'rb') as f:
            self.read_csi_file(f)
            

    def read_csi_file(self, f):
        n = 0
        while True:
            n = n + 1
            print('\n* file no.{}\n'.format(n))

            n2 = f.read(2)
            if n2 == b'': break
            csi_data_len = struct.unpack('>H', n2)[0]
            csi_data = f.read(csi_data_len)

            if self.csist_callback:
                self.csist_callback(incsi_st(csi_data).csist)



